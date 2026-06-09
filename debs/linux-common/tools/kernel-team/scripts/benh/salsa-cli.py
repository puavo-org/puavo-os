#!/usr/bin/env python3

import base64
from debian import deb822
import os
import pprint
import requests
import sys
import urllib.parse

API_URL="https://salsa.debian.org/api/v4/"

class SalsaSession:
    '''Wrappper around requests.Session with some helper methods'''
    def __init__(self):
        self._session = requests.Session()
        with open("TOKEN", 'r') as f:
            self._token = f.read().strip()

    def request(self, method, *args, **kwargs):
        '''
        Runs a request
         args = parts of request, url encoded, then joined with /
         kwargs = passed to requests api
        '''

        # Construct request URL
        url = API_URL + '/'.join((urllib.parse.quote_plus(str(x)) for x in args))

        # Add our private token header
        headers = kwargs.pop("headers", {})
        headers["Private-Token"] = self._token

        # Log all non-get queries
        if method != "get":
            print(method, url, kwargs)

        # Perform the request and check for errors
        r = self._session.request(method, url, headers=headers, **kwargs)
        r.raise_for_status()
        if r.status_code != 204:
            return r.json()

    def get(self, *args, **kwargs):
        return self.request('get', *args, **kwargs)

    def get_unpaginated(self, *args, **kwargs):
        '''Like get, but get the entire unpaginated response'''
        params = kwargs.pop("params", {})
        params["per_page"] = 100
        params["page"] = 1

        result = []
        while True:
            result_page = self.get(*args, params=params, *kwargs)
            if result_page:
                result.extend(result_page)
                params["page"] += 1
            else:
                return result

    def post(self, *args, **kwargs):
        return self.request('post', *args, **kwargs)

    def put(self, *args, **kwargs):
        return self.request('put', *args, **kwargs)

    def delete(self, *args, **kwargs):
        return self.request('delete', *args, **kwargs)

class GroupConfig:
    '''Stores the configuration settings for a group'''
    def __init__(self, path, maintainer, hooks_present, hooks_absent=[]):
        self.path = path
        self.maintainer = maintainer
        self.hooks_present = hooks_present
        self.hooks_absent = hooks_absent

class HookResult:
    '''Hook exists and has correct config'''
    GOOD = 0

    '''Hook exists but has bad config'''
    BAD = 1

    '''Hook does not exist / inactive'''
    NON_EXISTANT = 2

    '''Hook needs source package but none was given'''
    NEEDS_SOURCE = 3

class HookService:
    '''Base class for "service" style hooks'''
    def properties_for_project(self, project, source):
        '''
        Returns dict containing correct properties config for a project
        or NEEDS_SOURCE if source is needed and not given.
        '''
        raise NotImplementedError

    def audit(self, s, project, source):
        try:
            live_data = s.get("projects", project["id"], "services", self.name)
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return (HookResult.NON_EXISTANT, None)
            raise

        if live_data["active"]:
            good_props = self.properties_for_project(project, source)
            if good_props == HookResult.NEEDS_SOURCE:
                return (HookResult.NEEDS_SOURCE, None)

            # Validate each config entry
            record = []
            if not live_data["push_events"]:
                record.append("push events disabled")
            if not live_data["tag_push_events"]:
                record.append("tag events disabled")

            for key, value in good_props.items():
                if live_data["properties"][key] != value:
                    record.append(key + " is wrong")

            if record:
                return (HookResult.BAD, record)
            else:
                return (HookResult.GOOD, None)
        else:
            return (HookResult.NON_EXISTANT, None)

    def add(self, s, project, source):
        '''
        Adds a service, knowing it does not currently exist
         Returns GOOD or NEEDS_SOURCE
        '''
        props = self.properties_for_project(project, source)
        if props == HookResult.NEEDS_SOURCE:
            return HookResult.NEEDS_SOURCE

        s.put("projects", project["id"], "services", self.name, data=props)
        return HookResult.GOOD

    def delete(self, s, project, source):
        '''Deletes a service'''
        s.delete("projects", project["id"], "services", self.name)
        return HookResult.GOOD

class HookEmail(HookService):
    '''Emails on push service'''
    def __init__(self):
        self.name = "emails-on-push"

    def properties_for_project(self, project, source):
        if source:
            return { "recipients": "dispatch+" + source + "_vcs@tracker.debian.org" }
        else:
            return HookResult.NEEDS_SOURCE

class HookIrker(HookService):
    '''Irker IRC notifications service'''
    def __init__(self, server, irc_uri, channel):
        self.name = "irker"
        self.server = server
        self.irc_uri = irc_uri
        self.channel = channel

    def properties_for_project(self, project, source):
        return  {
            "colorize_messages": True,
            "default_irc_uri": self.irc_uri,
            "recipients": self.channel,
            "server_host": self.server
        }

class HookWebhook:
    '''Base class for "webhook" style hooks'''
    def url_for_project(self, project, source):
        '''
        Returns the URL for this webhook or NEEDS_SOURCE if source is needed
        and not given.
        '''
        raise NotImplementedError

    def find_hook(self, s, project, url):
        '''
        Returns information about a hook with the given url in a project or None
        if no hook exists.
        '''
        for hook in s.get("projects", project["id"], "hooks"):
            if hook["url"] == url:
                return hook

        return None

    def audit(self, s, project, source):
        url = self.url_for_project(project, source)
        if url == HookResult.NEEDS_SOURCE:
            return (HookResult.NEEDS_SOURCE, None)

        hook = self.find_hook(s, project, url)
        if hook:
            record = []
            if not hook["enable_ssl_verification"]:
                record.append("ssl verification disabled")

            # Currently hardcoded to check push events only
            if not hook["push_events"]:
                record.append("push events disabled")

            if record:
                return (HookResult.BAD, record)
            else:
                return (HookResult.GOOD, None)
        else:
            return (HookResult.NON_EXISTANT, None)

    def add(self, s, project, source):
        '''
        Adds a webhook, knowing it does not currently exist
         Returns GOOD or NEEDS_SOURCE
        '''
        url = self.url_for_project(project, source)
        if url == HookResult.NEEDS_SOURCE:
            return HookResult.NEEDS_SOURCE

        data = {
            "url": url,
            "enable_ssl_verification": True
        }
        for event in self.which_events():
            data[event] = True

        s.post("projects", project["id"], "hooks", data=data)
        return HookResult.GOOD

    def delete(self, s, project, source):
        '''Deletes a webhook'''
        url = self.url_for_project(project, source)
        if url == HookResult.NEEDS_SOURCE:
            return HookResult.NEEDS_SOURCE

        hook = self.find_hook(s, project, url)
        if hook:
            s.delete("projects", project["id"], "hooks", hook["id"])
        return HookResult.GOOD

    def which_events(self):
        '''Return sequence of events to be hooked'''
        return ["push_events"]

class HookTagPending(HookWebhook):
    '''Hook which marks closed bugs as pending'''
    def __init__(self):
        self.name = "bts pending hook"

    def url_for_project(self, project, source):
        if source:
            return "https://webhook.salsa.debian.org/tagpending/" + source
        else:
            return HookResult.NEEDS_SOURCE

class HookKGB(HookWebhook):
    '''KGB IRC notification hook'''
    def __init__(self, channel, use_notices=True, max_commits=None):
        self.name = "KGB IRC notification hook"
        self.channel = channel
        self.use_notices = use_notices
        self.max_commits = max_commits

    def url_for_project(self, project, source):
        url = ("http://kgb.debian.net:9418/webhook/?channel=%s&use_irc_notices=%d"
               % (urllib.parse.quote_plus(self.channel), self.use_notices))
        if self.max_commits is not None:
            url += '&squash_threshold=%d' % self.max_commits
        return url

    def which_events(self):
        return ["push_events",
                "tag_push_events",
                "merge_requests_events",
                "pipeline_events"]


def task_audit(group, fix, project_names):
    def print_colour(colour, text):
        if os.isatty(0):
            print(colour, end='')
            print(text, end='')
            print('\033[0m')
        else:
            print(text)

    s = SalsaSession()
    for project in s.get_unpaginated("groups", group.path, "projects",
            params={"order_by": "path", "sort": "asc", "archived": False}):
        if project_names and project['path'] not in project_names:
            continue

        record = []
        source_name = None

        print(project['path'] + ': ', end='')

        # Ignore projects which are shared with us
        if project["namespace"]["path"] != group.path:
            print_colour('\033[93m', "IGNORE")
            continue

        # Basics
        if project["visibility"] != "public":
            record.append("not public")
            if fix:
                s.put("projects", project["id"], data={"visibility": "public"})
                record[-1] += " (fixed)"

        # Is it a package or not?
        try:
            s.get("projects",
                  project["id"],
                  "repository",
                  "files",
                  "debian/changelog",
                  params={"ref": project["default_branch"]})
        except requests.exceptions.HTTPError:
            is_package = False
        else:
            is_package = True

        if project["issues_enabled"] == is_package:
            if is_package:
                record.append("issues enabled")
            else:
                record.append("issues disabled")
            if fix:
                s.put("projects", project["id"],
                      data={"issues_enabled": str(int(not is_package))})
                record[-1] += " (fixed)"

        if is_package:
            # debian/control
            control_file = None
            for filename in ["debian/control",
                             "debian/templates/control.source.in",
                             "debian/templates/source.control.in"]:
                try:
                    control_file = s.get(
                        "projects",
                        project["id"],
                        "repository",
                        "files",
                        filename,
                        params={"ref": project["default_branch"]})
                except requests.exceptions.HTTPError:
                    pass
                else:
                    break

            if control_file:
                control_data = None
                try:
                    control_data = base64.b64decode(control_file["content"]).decode("utf-8")
                except UnicodeError:
                    record.append("debian/control: invalid utf-8")

                if control_data:
                    control_dict = deb822.Deb822(control_data)
                    source_name = control_dict.get("Source", project["path"])
                    if filename == "debian/control" \
                       and "Source" not in control_dict:
                        record.append("debian/control: no Source field")
                    if "Source" in control_dict \
                       and control_dict["Source"] != project["path"]:
                        record.append("debian/control: Source does not patch project name")
                    if control_dict.get("Vcs-Git", "") != project["http_url_to_repo"]:
                        record.append("debian/control: wrong Vcs-Git")
                    if control_dict.get("Vcs-Browser", "") != project["web_url"]:
                        record.append("debian/control: wrong Vcs-Browser")
                    if control_dict.get("Maintainer", "").casefold() != group.maintainer.casefold():
                        record.append("debian/control: wrong Maintainer")
                else:
                    record.append("debian/control: does not exist")

        # Present hooks
        for hook in group.hooks_present:
            (result, record_extra) = hook.audit(s, project, source_name)
            if result in (HookResult.BAD, HookResult.NON_EXISTANT):
                if result == HookResult.NON_EXISTANT:
                    record_extra = ["disabled"]

                if fix:
                    if result == HookResult.BAD:
                        hook.delete(s, project, source_name)
                    hook.add(s, project, source_name)
                    record_extra = (x + " (fixed)" for x in record_extra)

                record.extend((hook.name + ": " + x for x in record_extra))

        # Absent hooks
        for hook in group.hooks_absent:
            (result, _) = hook.audit(s, project, source_name)
            if result in (HookResult.GOOD, HookResult.BAD):
                record.append(hook.name + ": enabled, but should not be")
                if fix:
                    hook.delete(s, project, source_name)
                    record[-1] += " (fixed)"

        # Report issues
        if record:
            print_colour('\033[91m', "FAIL")
            for issue in record:
                print(" ", issue)
        else:
            print("ok")

def task_get(parts):
    pprint.pprint(SalsaSession().get(*parts))

def task_import(group, project, import_url, description=None):
    s = SalsaSession()

    # Create project
    data = {
            "path": project,
            "namespace_id": s.get("namespaces", group.path)["id"],
            "description": description or ("Debian %s repository" % project),
            "issues_enabled": "no",
            "visibility": "public",
            "import_url": import_url
        }
    project_data = s.post("projects", data=data)

    # Setup present hooks
    for hook in group.hooks_present:
        hook.add(s, project_data, project)

    # Print project data
    pprint.pprint(project_data)

KERNEL_TEAM = GroupConfig(
        "kernel-team",
        "Debian Kernel Team <debian-kernel@lists.debian.org>",
        [HookEmail(),
         HookKGB("debian-kernel", use_notices=False, max_commits=10)],
        # Old KGB hook settings
        [HookKGB("debian-kernel", use_notices=False)],
    )

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == "audit":
        fix = len(sys.argv) > 2 and sys.argv[2] == "-f"
        task_audit(KERNEL_TEAM, fix, sys.argv[2 + fix :])
    elif len(sys.argv) > 2 and sys.argv[1] == "get":
        task_get(sys.argv[2:])
    elif len(sys.argv) > 3 and sys.argv[1] == "import":
        task_import(KERNEL_TEAM, *sys.argv[2:])
    else:
        print("usage:")
        print("  audit [-f] <project...>         = team repositories audit")
        print("  get <parts...>                  = get arbitrary salsa url")
        print("  import <package> <url> [<desc>] = import package from url")
        sys.exit(1)
