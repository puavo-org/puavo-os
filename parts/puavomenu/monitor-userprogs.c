/*
================================================================================
monitor-userprogs

Monitors the given directory for changes, and whenever something changes,
sends a reload message to puavomenu. This way the menu can keep live track
of user's own custom programs.

(c) Opinsys Oy 2020
License: GNU GPL 2
================================================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/inotify.h>

#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <errno.h>
#include <poll.h>
#include <unistd.h>

char *strsignal(int sig);

// -----------------------------------------------------------------------------

static int exists(const char *name)
{
    if (!name)
        return 0;

    if (access(name, F_OK) != 0)
        return 0;

    if (access(name, R_OK) != 0)
        return 0;

    return 1;
}

static int is_dir(const char *name)
{
    struct stat s;
    const int err = stat(name, &s);

    if (err != 0)
        return 0;

    if (S_ISDIR(s.st_mode))
        return 1;

    return 0;
}

// -----------------------------------------------------------------------------

static void notify_puavomenu(const char *socket_file)
{
    if (!socket_file)
        return;

    // Can't the use exec*() functions, as they kill this program if
    // send_command fails and no, I really don't want that. What
    // send_command does (or does not do) with the parameters is
    // not our concern.
    const size_t len = strlen(socket_file);
    char *cmd = calloc(1, len + 64);

    sprintf(cmd, "/opt/puavomenu/send_command %s reload-userprogs", socket_file);
    system(cmd);
    free(cmd);
}

// -----------------------------------------------------------------------------

static void read_events(int fd, const char *socket_file)
{
    // Alignment taken from the example code of inotify.
    // I don't know if it actually does anything.
    char buf[4096] __attribute__ ((aligned(__alignof__(struct inotify_event))));
    size_t numEvents = 0;

    for (;;) {
        const ssize_t len = read(fd, buf, sizeof(buf));

        if (len == -1 && errno != EAGAIN) {
            // read errors are fatal and halt the program
            perror("read_events(): read error");
            close(fd);
            exit(1);
        }

        if (len <= 0)
            break;

        // We don't actually care about these events. Only their existence
        // matters, not their contents.
        for (char *ptr = buf; ptr < buf + len; ) {
            const struct inotify_event *event = (const struct inotify_event *)ptr;

            ptr += sizeof(struct inotify_event) + event->len;

            // We only care about .desktop files
            if (event->len) {
                const char *dot = strrchr(event->name, '.');

                if (dot && strcmp(dot, ".desktop") == 0)
                    numEvents++;
            }
        }
    }

    if (numEvents)
        notify_puavomenu(socket_file);
}

static int inotify_fd = -1;

enum {
    POLLING_ERROR,
    DIRECTORY_DELETED,
};

static int monitor_dir(const char *dir_name, const char *socket_file)
{
    // Create the file descriptor for accessing the inotify API
    inotify_fd = inotify_init1(IN_NONBLOCK);

    if (inotify_fd == -1) {
        perror("monitor_dir()");
        return POLLING_ERROR;
    }

    // Start watching the directory
    inotify_add_watch(
        inotify_fd, dir_name,
        IN_DELETE_SELF | IN_MOVE_SELF |
        IN_CREATE | IN_MODIFY | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM
    );

    // Polling loop
    nfds_t nfds = 1;
    struct pollfd fds[1];

    fds[0].fd = inotify_fd;
    fds[0].events = POLLIN;

    while (1) {
        const int poll_num = poll(fds, nfds, -1);

        if (poll_num == -1) {
            if (errno == EINTR)
                continue;

            perror("monitor_dir()");

            close(inotify_fd);
            inotify_fd = -1;

            return POLLING_ERROR;
        }

        if (poll_num > 0 && fds[0].revents & POLLIN) {
            read_events(inotify_fd, socket_file);

            if (!exists(dir_name)) {
                notify_puavomenu(socket_file);
                break;
            }
        }
    }

    // We get here only if the directory is removed while we're watching it
    close(inotify_fd);
    inotify_fd = -1;

    return DIRECTORY_DELETED;
}

// -----------------------------------------------------------------------------

static const char *help =
"puavomenu user programs directory update watcher v0.9\n"
"(c) Opinsys Oy 2020\n"
"\n"
"Usage: monitor-userprogs <target directory> <puavomenu socket file>\n\n"
"If the target directory exists, the program starts to monitor its contents with\n"
"inotify. (If the directory does not exist yet, the program sits in a loop, re-\n"
"checking the directory every 15 minutes until it becomes available or the\n"
"program is stopped.)\n"
"\n"
"Whenever something changes in the directory, the program sends a \"reload-userprogs\"\n"
"message to puavomenu (hence the socket file requirement), so that it can reload\n"
"the user programs menu.\n"
"\n"
"If the directory is deleted at run-time, the program stops monitoring it and\n"
"goes back to the beginning, waiting for it to become available again.\n"
"\n"
"WARNING: The socket file name is passed as-is to system() calls. The\n"
"\"send_command\" call is executed as the current user, so the damage you can do\n"
"with this 'exploit' is limited.\n";

static const int DIRECTORY_RECHECK_TIME = 60 * 15,
                 START_OVER_TIME = 30;

void exit_handler(int sig)
{
    printf("Received signal %d (%s), exiting\n", sig, strsignal(sig));

    if (inotify_fd != -1) {
        close(inotify_fd);
        inotify_fd = -1;
    }

    exit(0);
}

int main(int argc, char *argv[])
{
    if (argc != 3) {
        puts(help);
        return 1;
    }

    // Setup signal handlers for clean exits
    signal(SIGQUIT, exit_handler);
    signal(SIGINT, exit_handler);
    signal(SIGHUP, exit_handler);

    while (1) {
        // If the target directory does not exist, sit in a really slow loop
        // and wait until it does. Bail out if it's not a directory.
        while (!exists(argv[1])) {
            printf("Directory \"%s\" does not exist, recheck in %d seconds\n",
                   argv[1], DIRECTORY_RECHECK_TIME);
            sleep(DIRECTORY_RECHECK_TIME);
        }

        if (!is_dir(argv[1])) {
            printf("ERROR: \"%s\" is not a directory that can be accessed, recheck in %d seconds\n",
                  argv[1], DIRECTORY_RECHECK_TIME);
            sleep(DIRECTORY_RECHECK_TIME);
        } else {
            // Target exists and is a directory
            printf("Monitoring the changes in directory \"%s\"\n", argv[1]);
            fflush(stdout);

            // do the initial update
            notify_puavomenu(argv[2]);

            const int ret = monitor_dir(argv[1], argv[2]);

            if (ret == DIRECTORY_DELETED) {
                // The directory was deleted, restart the loop
                printf("Directory \"%s\" no longer exists, starting over in %d seconds\n",
                       argv[1], START_OVER_TIME);

                notify_puavomenu(argv[2]);
                sleep(START_OVER_TIME);
            } else if (ret == POLLING_ERROR) {
                // Something went wrong in the polling loop, restart
                printf("Polling error! Starting over in %d seconds...\n",
                       START_OVER_TIME);

                sleep(START_OVER_TIME);
            }
        }
    }

    // We should never get here...
    printf("How did we get here?");
    return 1;
}
