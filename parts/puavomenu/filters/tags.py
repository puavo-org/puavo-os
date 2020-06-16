# For explicitly hiding (and showing) programs, menus, categories and more

import re
import logging


# A single action that either shows or hides something
class Action:
    # What this action does?
    HIDE = 0
    SHOW = 1

    # What type of object this action targets?
    TAG = 0
    PROGRAM = 1
    MENU = 2
    CATEGORY = 3

    ACTIONS_FOR_LOGGER = {
        HIDE: 'hide',
        SHOW: 'show'
    }

    TARGETS_FOR_LOGGER = {
        TAG: 'tag',
        PROGRAM: 'program',
        MENU: 'menu',
        CATEGORY: 'category'
    }


    def __init__(self, action, target, name, original):
        self.action = action
        self.target = target
        self.name = name
        self.original = original        # useful for logging purposes


    def __str__(self):
        return '<Filter action: {0} {1} "{2}">'.format(
            self.ACTIONS_FOR_LOGGER[self.action],
            self.TARGETS_FOR_LOGGER[self.target],
            self.name)


# Zero or more actions that are applied to programs, menus,
# categories and programs tagged with certain tags
class Filter:
    def __init__(self, initial=None, strict_reject=True):
        self.actions = []

        if initial:
            self.parse_string(initial, strict_reject)


    def have_data(self):
        return len(self.actions) > 0


    def reset(self):
        self.actions = []


    # Checks if a specific filter action exists. 'name' can be (optionally)
    # used to make the match even more exact.
    def has_action_for(self, action, target, name=None):
        for a in self.actions:
            if a.action == action and a.target == target:
                # Action and target matches. If the optional name is
                # specified, match it too.
                if name:
                    if a.name == name:
                        return True
                    else:
                        return False
                else:
                    # Action and target matches are enough
                    return True

        return False


    # If 'strict_reject' is True, the entire tag string is rejected
    # if it contains even one error. If it's False, mistakes are
    # simply ignored and the remaining parts are used.
    def parse_string(self, tag_string, strict_reject=True):
        logging.info('Filter::parse_string(): parsing "%s"', str(tag_string))

        tags = [tag.strip() for tag in re.split(r',|;|\ ', str(tag_string) if tag_string else '')]
        tags = filter(None, tags)
        tags = [p.lower() for p in tags]

        self.reset()

        for tag in tags:
            orig_tag = tag

            # Default actions
            action = Action.SHOW
            target = Action.TAG

            # Show or hide?
            if tag[0] == '+':
                action = Action.SHOW
                tag = tag[1:]
            elif tag[0] == '-':
                action = Action.HIDE
                tag = tag[1:]

            # What are we targeting?
            namespace = 't'
            sep = tag.find(':')

            if sep != -1:
                namespace = tag[:sep]
                tag = tag[sep+1:]

            if len(namespace) == 0 or len(tag) == 0:
                if strict_reject:
                    logging.error(
                        'Filter::parse_string(): rejecting filter string "%s" because "%s" '
                        'is not a valid tag', tag_string, orig_tag)
                    self.reset()
                    return
                else:
                    logging.warning(
                        'Filter::parse_string(): "%s" is not a valid tag, ignoring it',
                        orig_tag)

                continue

            # The tag can contain + and - characters, but it can't start
            # with them
            if (tag.find('-') == 0) or (tag.find('+') == 0):
                if strict_reject:
                    logging.error(
                        'Filter::parse_string(): rejecting filter string "%s" because "%s" '
                        'is not a valid tag', tag_string, orig_tag)
                    self.reset()
                    return
                else:
                    logging.warning(
                        'Filter::parse_string(): "%s" is not a valid tag, ignoring it',
                        orig_tag)

                continue

            if namespace in ('t', 'tag'):
                target = Action.TAG
            elif namespace in ('p', 'prog', 'program'):
                target = Action.PROGRAM
            elif namespace in ('m', 'menu'):
                target = Action.MENU
            elif namespace in ('c', 'cat', 'category'):
                target = Action.CATEGORY
            else:
                if strict_reject:
                    logging.error(
                        'Filter::parse_string(): rejecting filter string "%s" because "%s" '
                        'is not a valid tag namespace',
                        tag_string, namespace)
                    self.reset()
                    return
                else:
                    logging.warning(
                        'Filter::parse_string(): "%s" is not a valid tag namespace, ignoring tag',
                        orig_tag)

                continue

            self.actions.append(Action(action, target, tag, orig_tag))

            logging.debug(
                'Filter action: %s %s "%s"',
                Action.ACTIONS_FOR_LOGGER[action],
                Action.TARGETS_FOR_LOGGER[target],
                tag)
