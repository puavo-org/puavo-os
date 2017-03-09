# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
#if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	        # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
		   /usr/lib/command-not-found -- "$1"
                   return $?
                elif [ -x /usr/share/command-not-found/command-not-found ]; then
		   /usr/share/command-not-found/command-not-found -- "$1"
                   return $?
		else
		   printf "%s: command not found\n" "$1" >&2
		   return 127
		fi
	}
fi

if [ "$(id -u)" = 0 ] || (groups | fgrep -qw puavo-os); then
  _puavo_image_name=$(cat /etc/puavo-image/name)
  _puavo_host_profiles=$(timeout -k 1 3 puavo-conf puavo.profiles.list 2>/dev/null || true)

  if [ -z "$_puavo_host_profiles" ]; then
    _puavo_host_profiles=$(timeout -k 1 3 puavo-conf puavo.hosttype 2>/dev/null || true)
    if [ -z "$_puavo_host_profiles" ]; then
      _puavo_host_profiles='???'
    fi
  fi

  if [ "$(id -u)" = 0 ]; then
    _puavo_prompt_colornum=31
    # red prompt for root
  else
    # magenta prompt for adm users
    _puavo_prompt_colornum=35
  fi

  PS1="\[\e[1;${_puavo_prompt_colornum}m\]> ${_puavo_image_name%.img} (${_puavo_host_profiles})\n\u@\h:\w\$\[\e[0m\] "

  unset _puavo_host_profiles
  unset _puavo_image_name
  unset _puavo_prompt_colornum
fi
