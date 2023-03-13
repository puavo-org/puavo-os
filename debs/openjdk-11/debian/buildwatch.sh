#! /bin/sh

#
# Output something to stdout every so often so buildd won't kill
# the build when building 
#

builddir=$1

echo $$ > buildwatch.pid

time_unit="m"
timer=0
sleep_for=3
time_up_at=180
upd_every=30 # use a multiple of $sleep_for

reset_timer() { timer=0; }
inc_timer()   { timer=$(expr $timer + $sleep_for); }
time_up()     { [ $timer -ge $time_up_at ]; }
can_update()  { [ $(expr $timer % $upd_every) -eq 0 ]; }
do_sleep()    { sleep ${sleep_for}${time_unit} && inc_timer; }

is_running() { 
    ps x | grep -v grep | egrep -qs $@
    return $?
}

cleanup() {
    # find any hs_err_pid files generated during the build and print them out
    # this helps debugging what went wrong during builds
    find . -type f -name 'hs_err_pid*.log' -printf "[$0] === HOTSPOT ERROR LOG ===\n[$0] %p (last modification at %t)\n" -exec cat {} \;
}

for sig in INT QUIT HUP TERM; do trap "cleanup; trap - $sig EXIT; kill -s $sig "'"$$"' "$sig"; done
trap cleanup EXIT

while ! time_up; do
    if [ ! -f buildwatch.pid ]; then
        echo "[$0] pidfile removed" && break
    fi
    if ! is_running '/make'; then
        echo "[$0] no make process detected (build done?)" && break
    fi

    do_sleep
    can_update || continue

    new_noisy=$(ls -l test/jtreg_output-* 2>&1 | md5sum)
    new_quiet=$(ls -l $builddir/openjdk*/build/*/tmp/rt-orig.jar $builddir/openjdk*/build/*/lib/tools.jar $builddir/openjdk*/build/*/lib/ct.sym 2>&1 | md5sum)
    if [ -n "$old_noisy" -a "$old_noisy" != "$new_noisy" ]; then
        # jtreg updated test files, so it should be updating stdout in its own
        # keep quiet and restart timer
        reset_timer
    elif [ -n "$old_quiet" -a "$old_quiet" != "$new_quiet" ]; then
        reset_timer
        echo "[$0] assembling jar file ..."
    elif is_running '/cc1|jar|java|gij'; then
        echo "[$0] compiler/java/jar running ..."
        reset_timer
    fi
    old_noisy=$new_noisy
    old_quiet=$new_quiet
done

echo "[$0] exiting"
rm -f buildwatch.pid
