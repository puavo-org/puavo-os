/* puavo-conf-update
 * Copyright (C) 2016 Opinsys Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#define _GNU_SOURCE

#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include <err.h>
#include <fcntl.h>
#include <getopt.h>
#include <glob.h>
#include <jansson.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "conf.h"

#define DEVICEJSON_PATH "/etc/puavo/device.json"
#define IMAGE_CONF_PATH "/etc/puavo-conf/image.json"
#define PROFILES_DIR    "/usr/share/puavo-conf/profile-overwrites"

char *puavo_hosttype;

static int	 apply_device_settings(puavo_conf_t *, const char *, int);
static int	 apply_hosttype_profile(puavo_conf_t *, int);
static int	 apply_hwquirks(puavo_conf_t *, int);
static int	 apply_kernel_arguments(puavo_conf_t *, int);
static int	 apply_one_profile(puavo_conf_t *, const char *, int);
static int	 apply_profiles(puavo_conf_t *, int);
static char	*get_cmdline(void);
static int	 glob_error(const char *, int);
static int	 handle_one_paramdef(puavo_conf_t *, const char *, json_t *,
    int);
static int	 handle_paramdef_file(puavo_conf_t *, const char *, int);
static int	 init_with_parameter_definitions(puavo_conf_t *, int);
static int	 overwrite_value(puavo_conf_t *, const char *, const char *,
    int);
static json_t	*parse_json_file(const char *);
static int	 update_puavoconf(puavo_conf_t *, const char *, int);
static void	 usage(void);

int
main(int argc, char *argv[])
{
	puavo_conf_t *conf;
	struct puavo_conf_err err;
	const char *device_json_path;
	static struct option long_options[] = {
	    { "devicejson-path", required_argument, 0, 0 },
	    { "help",            no_argument,       0, 0 },
	    { "init",            no_argument,       0, 0 },
	    { "verbose",         no_argument,       0, 0 },
	    { 0,                 0,                 0, 0 },
	};
	int c, init, option_index, status, verbose;

	init = 0;
	status = 0;
	verbose = 0;

	device_json_path = DEVICEJSON_PATH;

	for (;;) {
		option_index = 0;
		c = getopt_long(argc, argv, "", long_options, &option_index);
		if (c == -1)
			break;

		if (c != 0) {
			usage();
			return 1;
		}

		switch (option_index) {
		case 0:
			device_json_path = optarg;
			break;
		case 1:
			usage();
			return 0;
		case 2:
			init = 1;
			break;
		case 3:
			verbose = 1;
			break;
		default:
			usage();
			return 1;
		}
	}

	if (optind < argc) {
		usage();
		return 1;
	}

	if (puavo_conf_open(&conf, &err))
		errx(1, "Failed to open config backend: %s", err.msg);

	if (init) {
		if (init_with_parameter_definitions(conf, verbose) != 0) {
			warnx("failure in initializing puavo conf db");
			status = EXIT_FAILURE;
		}
	}

	if (update_puavoconf(conf, device_json_path, verbose) != 0) {
		warnx("problem in updating puavoconf");
		status = EXIT_FAILURE;
	}

	if (puavo_conf_close(conf, &err) == -1) {
		warnx("Failed to close config backend: %s", err.msg);
		status = EXIT_FAILURE;
	}

	return status;

	return 0;
}

static void
usage(void)
{
	printf("Usage:\n"
	       "    puavo-conf-update [OPTION]...\n"
	       "\n"
	       "Update configuration database by overwriting parameter values\n"
	       "from the following sources, in the given order:\n"
	       "\n"
	       "  1. image specific settings from " IMAGE_CONF_PATH "\n"
	       "  2. hardware quirks\n"
	       "  3. device specific settings from " DEVICEJSON_PATH "\n"
	       "  4. kernel command line\n"
	       "\n"
	       "Options:\n"
	       "  --help                    display this help and exit\n"
	       "  --devicejson-path FILE    filepath of the device.json,\n"
	       "                            defaults to " DEVICEJSON_PATH "\n"
	       "  --init                    initialize the database\n"
	       "  --verbose                 verbose output\n"
	       "\n");
}

static int
init_with_parameter_definitions(puavo_conf_t *conf, int verbose)
{
	glob_t globbuf;
	size_t i;
	int ret, retvalue;

	retvalue = 0;

	ret = glob("/usr/share/puavo-conf/definitions/*.json", 0, glob_error,
	    &globbuf);
	if (ret != 0) {
		warnx("glob() failure in init_with_parameter_definitions()");
		globfree(&globbuf);
		return 1;
	}

	for (i = 0; i < globbuf.gl_pathc; i++) {
		ret = handle_paramdef_file(conf, globbuf.gl_pathv[i], verbose);
		if (ret != 0) {
			warnx("error handling %s", globbuf.gl_pathv[i]);
			/* Return error, but try other files. */
			retvalue = 1;
		}
	}

	globfree(&globbuf);

	return retvalue;
}

static int
glob_error(const char *epath, int errno)
{
	warnx("glob error with %s: %s", epath, strerror(errno));

	return 1;
}

static int
handle_paramdef_file(puavo_conf_t *conf, const char *filepath, int verbose)
{
	json_t *root, *param_value;
	const char *param_name;
	int ret, retvalue;

	retvalue = 0;

	if ((root = parse_json_file(filepath)) == NULL) {
		warnx("parse_json_file() failed for %s", filepath);
		return 1;
	}

	if (!json_is_object(root)) {
		warnx("root is not a json object in %s", filepath);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(root, param_name, param_value) {
		ret = handle_one_paramdef(conf, param_name, param_value,
		    verbose);
		if (ret != 0) {
			warnx("error handling %s in %s", param_name, filepath);
			/* Return error, but try other keys. */
			retvalue = 1;
		}
	}

finish:
	json_decref(root);

	return retvalue;
}

static int
handle_one_paramdef(puavo_conf_t *conf, const char *param_name,
    json_t *param_value, int verbose)
{
	json_t *default_node;
	struct puavo_conf_err err;
	const char *value;

	if (!json_is_object(param_value)) {
		warnx("parameter %s does not have an object as value",
		    param_name);
		return 1;
	}

	if ((default_node = json_object_get(param_value, "default")) == NULL) {
		warnx("parameter %s does not have a default value", param_name);
		return 1;
	}

	if ((value = json_string_value(default_node)) == NULL) {
		warnx("parameter %s default is not a string", param_name);
		return 1;
	}

	if (puavo_conf_add(conf, param_name, value, &err) != 0) {
		warnx("error adding %s --> '%s' : %s", param_name, value,
		    err.msg);
		return 1;
	}

	if (verbose) {
		(void) printf("puavo-conf-update: initialized puavo conf key"
		    " %s --> %s\n", param_name, value);
	}

	return 0;
}

static int
update_puavoconf(puavo_conf_t *conf, const char *device_json_path, int verbose)
{
	int retvalue;

	retvalue = 0;

	/* First apply kernel arguments, because we get puavo.hosttype
	 * and puavo.profiles.list from there, which affect subsequent
	 * settings. */
	if (apply_kernel_arguments(conf, verbose) != 0)
		retvalue = 1;

	if (apply_one_profile(conf, IMAGE_CONF_PATH, verbose) != 0)
		retvalue = 1;

	if (apply_profiles(conf, verbose) != 0)
		retvalue = 1;

	if (apply_hwquirks(conf, verbose) != 0)
		retvalue = 1;

	if (apply_device_settings(conf, device_json_path, verbose) != 0)
		retvalue = 1;

	/* Apply kernel arguments again,
	 * because those override everything else. */
	if (apply_kernel_arguments(conf, verbose) != 0)
		retvalue = 1;

	return retvalue;
}

static int
apply_profiles(puavo_conf_t *conf, int verbose)
{
	struct puavo_conf_err err;
	char *profile, *profiles, *profile_path;
	int retvalue, ret;

	ret = puavo_conf_get(conf, "puavo.profiles.list", &profiles, &err);
	if (ret == -1) {
		warnx("error getting puavo.profiles.list: %s", err.msg);
		return 1;
	}

	/*
	 * If no profiles have been set, use puavo.hosttype variable as
	 * the profile name.
	 */
	if (strcmp(profiles, "") == 0) {
		if (verbose) {
			(void) printf("puavo-conf-update: applying hosttype"
			    " profile because puavo.profiles.list is not"
			    " set\n");
		}

		free(profiles);
		return apply_hosttype_profile(conf, verbose);
	}

	retvalue = 0;

	while ((profile = strsep(&profiles, ",")) != NULL) {
		ret = asprintf(&profile_path, PROFILES_DIR "/%s.json",
		    profile);
		if (ret == -1) {
			warnx("asprintf() error in apply_hosttype_profile()");
			retvalue = 1;
			continue;
		}

		if (apply_one_profile(conf, profile_path, verbose) != 0)
			retvalue = 1;
		free(profile_path);
	}

	free(profiles);

	return retvalue;
}

static int
apply_hosttype_profile(puavo_conf_t *conf, int verbose)
{
	struct puavo_conf_err err;
	char *hosttype;
	char *hosttype_profile_path;
	int ret, retvalue;

	if (puavo_conf_get(conf, "puavo.hosttype", &hosttype, &err) == -1) {
		warnx("error getting puavo.hosttype: %s", err.msg);
		return 1;
	}

	ret = asprintf(&hosttype_profile_path, PROFILES_DIR "/%s.json",
	    hosttype);
	if (ret == -1) {
		warnx("asprintf() error in apply_hosttype_profile()");
		free(hosttype);
		return 1;
	}

	retvalue = 0;

	if (apply_one_profile(conf, hosttype_profile_path, verbose) != 0)
		retvalue = 1;

	free(hosttype);
	free(hosttype_profile_path);

	return retvalue;
}

static char *
get_cmdline(void)
{
	FILE *cmdline;
	char *line;
	size_t n;

	if ((cmdline = fopen("/proc/cmdline", "r")) == NULL) {
		warn("fopen /proc/cmdline");
		return NULL;
	}

	line = NULL;
	n = 0;
	if (getline(&line, &n, cmdline) == -1) {
		warn("getline() on /proc/cmdline");
		free(line);
		return NULL;
	}

	(void) fclose(cmdline);

	return line;
}

static int
apply_device_settings(puavo_conf_t *conf, const char *device_json_path,
    int verbose)
{
	json_t *root, *device_conf, *node_value;
	const char *param_name, *param_value;
	int ret, retvalue;

	retvalue = 0;

	if ((root = parse_json_file(device_json_path)) == NULL) {
		warnx("parse_json_file() failed for %s", device_json_path);
		return 1;
	}

	if (!json_is_object(root)) {
		warnx("device settings in %s are not in correct format",
		    device_json_path);
		retvalue = 1;
		goto finish;
	}

	if ((device_conf = json_object_get(root, "conf")) == NULL) {
		warnx("device settings in %s are lacking configuration values",
		    device_json_path);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(device_conf, param_name, node_value) {
		if ((param_value = json_string_value(node_value)) == NULL) {
			warnx("device settings in %s has a non-string value"
			    " for key %s", device_json_path, param_name);
			retvalue = 1;
			continue;
		}
		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

finish:
	json_decref(root);

	return retvalue;
}

static int
apply_one_profile(puavo_conf_t *conf, const char *profile_path, int verbose)
{
	json_t *root, *node_value;
	const char *param_name, *param_value;
	int ret, retvalue;

	retvalue = 0;
	root = NULL;

	if (verbose) {
		(void) printf("puavo-conf-update: applying profile %s\n",
		    profile_path);
	}

	if ((root = parse_json_file(profile_path)) == NULL) {
		warnx("parse_json_file() failed for %s", profile_path);
		retvalue = 1;
		goto finish;
	}

	if (!json_is_object(root)) {
		warnx("profile %s is not in correct format", profile_path);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(root, param_name, node_value) {
		if ((param_value = json_string_value(node_value)) == NULL) {
			warnx("profile %s has a non-string value for key %s",
			    profile_path, param_name);
			retvalue = 1;
			continue;
		}
		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

finish:
	if (root != NULL)
		json_decref(root);

	return retvalue;
}

static int
apply_hwquirks(puavo_conf_t *conf, int verbose)
{
	/* XXX */
	return 0;
}

static int
apply_kernel_arguments(puavo_conf_t *conf, int verbose)
{
	char *cmdarg, *cmdline, *param_name, *param_value;
	size_t prefix_len;
	int ret, retvalue;

	(void) printf("puavo-conf-update: applying kernel arguments\n");

	cmdline = get_cmdline();
	if (cmdline == NULL) {
		warnx("could not read /proc/cmdline");
		return 1;
	}

	retvalue = 0;

	prefix_len = sizeof("puavo.") - 1;

	while ((cmdarg = strsep(&cmdline, " \t\n")) != NULL) {
		if (strncmp(cmdarg, "puavo.", prefix_len) != 0)
			continue;

		param_value = cmdarg;
		param_name = strsep(&param_value, "=");
		if (param_value == NULL)
			continue;

		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

	free(cmdline);

	return retvalue;
}

static int
overwrite_value(puavo_conf_t *conf, const char *key, const char *value,
    int verbose)
{
	struct puavo_conf_err err;

	if (puavo_conf_overwrite(conf, key, value, &err) != 0) {
		warnx("error overwriting %s --> '%s' : %s", key, value,
		    err.msg);
		return 1;
	}

	if (verbose) {
		(void) printf("puavo-conf-update: setting puavo conf key %s"
		    " --> %s\n", key, value);
	}

	return 0;
}

static json_t *
parse_json_file(const char *filepath)
{
	json_t *root;
	json_error_t error;
	const char *json;
	off_t len;
	int fd;

	root = NULL;

	if ((fd = open(filepath, O_RDONLY)) == -1) {
		warn("open() on %s", filepath);
		return NULL;
	}

	if ((len = lseek(fd, 0, SEEK_END)) == -1) {
		warn("lseek() on %s", filepath);
		goto finish;
	}

	if ((json = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0)) == NULL) {
		warn("mmap() on %s", filepath);
		goto finish;
	}

	if ((root = json_loads(json, 0, &error)) == NULL) {
		warnx("error parsing json file %s line %d: %s", filepath,
		    error.line, error.text);
	}

finish:
	(void) close(fd);

	return root;
}

#if 0
  /* OLD RUBY CODE, STILL IMPLEMENTING THINGS MISSING FROM ABOVE: */

  #!/usr/bin/ruby

require 'getoptlong'
require 'json'

require 'puavo/conf'

def apply_parameter_filters(parameters, parameter_filters, lookup_fn)
    parameter_filters.each do |filter|
        validate_parameter_filter(filter)

        if filter['key'] == '*' then
            parameters.update(filter['parameters'])
            next
        end

        parameter_values = lookup_fn.call(filter['key'])
        next if parameter_values.nil?

        parameter_values.each do |value|
            match_result = match_puavopattern(value,
                                              filter['matchmethod'],
                                              filter['pattern'])
            if match_result then
                parameters.update(filter['parameters'])
                break
            end
        end
    end
end

def validate_value(value)
    return true if value.kind_of?(String)
    raise "Value has unsupported type"
end

def validate_parameter_filter(obj)
    unless obj.kind_of?(Hash)
        raise "Parameter filters must be an hash"
    end
    %w(key matchmethod pattern parameters).each do |required_key|
        unless obj.has_key?(required_key)
            raise "Parameter filter is missing required key '#{required_key}'"
        end
    end
    unless obj['key'].kind_of?(String)
        raise "Parameter filter's key is of wrong type"
    end
    unless %w(exact glob regex).include?(obj['matchmethod'])
        raise "Parameter filter's matchmethod has unknown value"
    end
    unless obj['pattern'].kind_of?(String)
        raise "Parameter filter's pattern is of wrong type"
    end
    unless obj['parameters'].kind_of?(Hash)
        raise "Parameter filter's parameters is of wrong type"
    end
    if obj['parameters'].empty?
        raise "Parameter filter's parameters is empty"
    end
    obj['parameters'].each do |key, value|
        unless key.kind_of?(String)
            raise "Parameter key must be a string"
        end
        validate_value(value)
    end
    true
end

def read_json_obj(file, type)
    obj = JSON.parse(IO.read(file))
    unless obj.kind_of?(type)
        raise "Top-level JSON object of #{file} is not #{type}"
    end
    obj
end

$deviceinfo = {}
def get_device_setting(key)
    # returns nil in case there was a failure
    return $deviceinfo[key] if $deviceinfo.has_key?(key)

    case key
        when 'dmidecode-baseboard-asset-tag',
             'dmidecode-baseboard-manufacturer',
             'dmidecode-baseboard-product-name',
             'dmidecode-baseboard-serial-number',
             'dmidecode-baseboard-version',
             'dmidecode-bios-release-date',
             'dmidecode-bios-vendor',
             'dmidecode-bios-version',
             'dmidecode-chassis-asset-tag',
             'dmidecode-chassis-manufacturer',
             'dmidecode-chassis-serial-number',
             'dmidecode-chassis-type',
             'dmidecode-chassis-version',
             'dmidecode-processor-family',
             'dmidecode-processor-frequency',
             'dmidecode-processor-manufacturer',
             'dmidecode-processor-version',
             'dmidecode-system-manufacturer',
             'dmidecode-system-product-name',
             'dmidecode-system-serial-number',
             'dmidecode-system-uuid',
             'dmidecode-system-version'
                cmdarg = key[ "dmidecode-".length .. -1]
                result = %x(dmidecode -s #{ cmdarg })
                status = $?.exitstatus
                if status != 0 then
                    logerr("dmidecode -s #{ cmdarg } returned #{ status }")
                    $deviceinfo[key] = nil
                else
                    $deviceinfo[key] = [ result.strip ]
                end
        when 'pci-id'
            # might return nil, that is okay
            $deviceinfo[key] = take_field('lspci -n', 3)
        when 'usb-id'
            # might return nil, that is okay
            $deviceinfo[key] = take_field('lsusb', 6)
        else
            logerr("Unknown device key #{ key }")
            $deviceinfo[key] = nil
    end

    return $deviceinfo[key]
end

def logwarn(msg)
    warn("Warning: #{msg}")
end

def logerr(msg)
    warn("Error: #{msg}")
    $status = 1
end

def match_puavopattern(target, matchmethod, pattern)
    # XXX if 'logic' matchmethod is going to be implemented
    # XXX pattern might not be a string?
    if !pattern.kind_of?(String) then
        logerr('input type error: match pattern is not a string')
        return
    end

    case matchmethod
        when 'exact'
            return target == pattern
        when 'glob'
            return File.fnmatch(pattern, target)
        when 'logic'
            logerr("Match method logic not implemented yet")
            return false
        when 'regex'
            return target.match(pattern) ? true : false
        else
            logerr("Match method #{ matchmethod } is unsupported")
    end

    return false
end

def take_field(cmd, fieldnum)
    result = %x(#{ cmd })
    status = $?.exitstatus
    if status != 0 then
        logerr("#{ cmd } returned #{ status }")
        return nil
    end

    result.split("\n").map { |line| (line.split(' '))[fieldnum-1] }
end

def usage()
    puts <<-EOF
Usage:
    puavo-conf-update [OPTION]...

Update configuration database by overwriting parameter values from the
following sources, in the given order:

  1. hardware quirks
  2. device specific settings from '#{$devicejson_path}'
  3. kernel command line

Options:
  --help, -h                  display this help and exit

  --devicejson-path FILE      filepath of the device.json, defaults to
                              '#{$devicejson_path}'

EOF
end

def get_hwquirk_params()
    parameters = {}
    files      = Dir.glob('/usr/share/puavo-conf/hwquirk-overwrites/*.json') rescue []

    files.each do |file|
        apply_parameter_filters(parameters,
                                read_json_obj(file, Array),
                                Proc.method(:get_device_setting))
    end

    return parameters
end

def get_devicejson_params()
    begin
        device = read_json_obj($devicejson_path, Hash)
    rescue Errno::ENOENT
        return {}
    end
    device['conf'] or {}
end

def get_kernelarg_params()
    parameters = {}

    IO.read('/proc/cmdline').split.each do |kernel_arg|
        if kernel_arg =~ /\A(puavo\..*)=(.*)\Z/
            parameters[$1] = $2
        end
    end

    return parameters
end

def get_profile_params(profile)
    return {} if profile.nil?

    begin
        read_json_obj("/usr/share/puavo-conf/profile-overwrites/#{profile}.json", Hash)
    rescue Errno::ENOENT
        {}
    end
end

  ## Main

$status = 0

$devicejson_path = '/etc/puavo/device.json'

begin
    opts = GetoptLong.new(['--help', '-h',      GetoptLong::NO_ARGUMENT],
                          ['--devicejson-path', GetoptLong::REQUIRED_ARGUMENT])

    opts.each do |opt, arg|
        case opt
            when '--help'
                usage
                exit 0
            when '--devicejson-path'
                $devicejson_path = arg
        end
    end

rescue GetoptLong::InvalidOption => e
    usage
    exit 1
end

params = {}

hwquirk_params    = get_hwquirk_params
devicejson_params = get_devicejson_params
kernelarg_params  = get_kernelarg_params
profile_params    = get_profile_params(kernelarg_params.delete('puavo.hosttype'))

params.update(profile_params)
params.update(hwquirk_params)
params.update(devicejson_params)
params.update(kernelarg_params)

puavoconf = Puavo::Conf.new()
begin
    params.each do |key, value|
        begin
            puavoconf.overwrite(key, value)
        rescue StandardError => e
            logerr("Failed to overwrite a parameter: " \
                   "#{key}=#{value}: #{e.message}")
        end
    end
ensure
    puavoconf.close
end

exit($status)

#endif
