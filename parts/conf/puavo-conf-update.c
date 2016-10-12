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

#define _BSD_SOURCE

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

char *puavo_hosttype;

static int	 apply_device_settings(puavo_conf_t *, char *);
static int	 apply_hosttype_profile(puavo_conf_t *, char *);
static int	 apply_hwquirks(puavo_conf_t *);
static int	 apply_kernel_arguments(puavo_conf_t *, char *);
static char	*get_cmdline(void);
static char	*get_puavo_hosttype(char *);
static int	 update_puavoconf(puavo_conf_t *, const char *);
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
	};
	int c, option_index, status;

	status = 0;

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

	if (update_puavoconf(conf, device_json_path) != 0) {
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
	       "  1. hardware quirks\n"
	       "  2. device specific settings from " DEVICEJSON_PATH "\n"
	       "  3. kernel command line\n"
	       "\n"
	       "Options:\n"
	       "  --help, -h                display this help and exit\n"
	       "\n"
	       "  --devicejson-path FILE    filepath of the device.json,\n"
	       "                            defaults to " DEVICEJSON_PATH "\n"
	       "\n");
}

static int
update_puavoconf(puavo_conf_t *conf, const char *device_json_path)
{
	char *cmdline;
	char *hosttype;
	int ret;

	ret = 0;

	cmdline = get_cmdline();
	if (cmdline == NULL) {
		warnx("could not read /proc/cmdline");
		ret = 1;
	}

	hosttype = NULL;
	if (cmdline != NULL)
		hosttype = get_puavo_hosttype(cmdline);

	if (hosttype != NULL) {
		if (apply_hosttype_profile(conf, hosttype) != 0)
			ret = 1;
	} else {
		warnx("skipping hosttype profile because hosttype not known");
		ret = 1;
	}

	if (apply_hwquirks(conf) != 0)
		ret = 1;

	if (apply_device_settings(conf, device_json_path) != 0)
		ret = 1;

	if (cmdline != 0) {
		if (apply_kernel_arguments(conf, cmdline) != 0)
			ret = 1;
	} else {
		warnx("skipping kernel arguments because those are not known");
		ret = 1;
	}

	free(cmdline);
	free(hosttype);

	return ret;
}

static char *
get_puavo_hosttype(char *cmdline)
{
	char *cmdarg, *hosttype;
	size_t prefix_len;
	int c;

	hosttype = NULL;

	prefix_len = sizeof("puavo.hosttype=") - 1;

	while ((cmdarg = strsep(&cmdline, " \t\n")) != NULL) {
		c = strncmp(cmdarg, "puavo.hosttype=", prefix_len);
		if (c == 0) {
			hosttype = strdup(&cmdarg[prefix_len]);
			if (hosttype == NULL)
				warn("strdup() error");
			break;
		}
	}

	if (hosttype == NULL)
		warnx("could not determine puavo hosttype");

	return hosttype;
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
apply_device_settings(puavo_conf_t *conf, char *device_json_path)
{
	/* XXX */
	return 0;
}

static int
apply_hosttype_profile(puavo_conf_t *conf, char *hosttype)
{
	/* XXX */
	return 0;
}

static int
apply_hwquirks(puavo_conf_t *conf)
{
	/* XXX */
	return 0;
}

static int
apply_kernel_arguments(puavo_conf_t *conf, char *cmdline)
{
	/* XXX */
	return 0;
}

#if 0

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
