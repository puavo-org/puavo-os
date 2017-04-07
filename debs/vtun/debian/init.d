#!/bin/sh -e
# vim:ts=4:sw=4:et:ai:sts=4:filetype=sh
### BEGIN INIT INFO
# Provides:          vtun
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      
# Short-Description: virtual tunnel over TCP/IP networks
### END INIT INFO
# Runlevels 0 and 6 removed from Default-Stop as the script only kills the
# daemon and that can be done by sendsigs, as sugested by Peter Reinholdtsen.

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/vtund
NAME=vtun
DESC="virtual tunnel daemon"
CONFFILE=/etc/vtund.conf
PIDPREFIX=/var/run/vtund

test -f $DAEMON || exit 0
test -f $CONFFILE || exit 0

. /lib/lsb/init-functions

# Include defaults if available
if [ -f /etc/default/$NAME ] ; then
        . /etc/default/$NAME
fi

mkdir -p /var/run/vtund /var/lock/vtund

case "$1" in
    start)
        if [ -f /etc/vtund-start.conf ]; then
            log_warning_msg "/etc/vtund-start.conf has been replaced!"
            if [ -e /usr/share/doc/vtun/NEWS.Debian.gz ]; then
                log_warning_msg "Please read /usr/share/doc/vtun/NEWS.Debian.gz"
            else
                log_warning_msg "Please read /usr/share/doc/vtun/NEWS.Debian"
            fi
        fi
        SOMETHING_STARTED=0
        if [ -n "$RUN_SERVER" ] && [ "$RUN_SERVER" != no ]; then
            log_daemon_msg "Starting $DESC server " "$NAME"
            start-stop-daemon --start --startas $DAEMON --oknodo \
                --pidfile $PIDPREFIX.server.pid -- -s $SERVER_ARGS
            log_end_msg $?
            SOMETHING_STARTED=1
        fi
        for i in 0 1 2 3 4 5 6 7 8 9; do
            eval name=\$CLIENT${i}_NAME
            eval host=\$CLIENT${i}_HOST
            eval args=\$CLIENT${i}_ARGS
            if [ -n "$name" ] && [ -n "$host" ]; then
                log_daemon_msg "Starting $DESC client $name to $host " "$NAME"
                start-stop-daemon --start --startas $DAEMON --oknodo \
                    --pidfile $PIDPREFIX.$name-$host.pid -- $name $host $args
                log_end_msg $?
                SOMETHING_STARTED=1
            fi
        done
        if [ "$SOMETHING_STARTED" -eq 0 ]; then
            log_failure_msg "$NAME disabled, please adjust the configuration to your needs "
            log_failure_msg "and then set RUN_SERVER to 'yes' or configure a client in "
            log_failure_msg "/etc/default/$NAME to enable it."
            exit 0
        fi
        ;;
    stop)
        for i in $PIDPREFIX*.pid; do
            test -f "$i" || continue
            log_daemon_msg "Stopping $DESC" "$NAME"
            start-stop-daemon --oknodo --stop --pidfile $i
            rm -f $i
        done
        ;;
    status)
    for i in 0 1 2 3 4 5 6 7 8 9; do
        eval name=\$CLIENT${i}_NAME
        eval host=\$CLIENT${i}_HOST
        status_of_proc -p $PIDPREFIX.$name-$host.pid $DAEMON vtund && e$
    done
    ;;
    reload|force-reload)
        echo "Reloading vtund.";
        for i in $PIDPREFIX*.pid; do
            test -f "$i" || continue
            start-stop-daemon --oknodo --stop --signal 1 --pidfile $i;
        done
        ;;
    restart)
        $0 stop
        sleep 1;
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|force-reload}" >&2
        exit 1
        ;;
esac
exit 0
