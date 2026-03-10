/* chez_inotify_shim.c — Linux inotify wrapper for Chez Scheme FFI */

#include <sys/inotify.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <poll.h>

/* Create an inotify instance with NONBLOCK and CLOEXEC flags.
   Returns fd or -errno. */
int chez_inotify_init(void) {
    int fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (fd < 0) return -errno;
    return fd;
}

/* Add a watch. Returns watch descriptor or -errno. */
int chez_inotify_add_watch(int fd, const char *path, unsigned int mask) {
    int wd = inotify_add_watch(fd, path, mask);
    if (wd < 0) return -errno;
    return wd;
}

/* Remove a watch. Returns 0 or -errno. */
int chez_inotify_rm_watch(int fd, int wd) {
    if (inotify_rm_watch(fd, wd) < 0) return -errno;
    return 0;
}

/* Read events into buffer. Returns bytes read, 0 if nothing available,
   or -errno on error. */
int chez_inotify_read(int fd, unsigned char *buf, int buflen) {
    int n = read(fd, buf, buflen);
    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) return 0;
        return -errno;
    }
    return n;
}

/* Poll for readability with timeout_ms (-1 = block, 0 = poll).
   Returns 1 if readable, 0 if timeout, -errno on error. */
int chez_inotify_poll(int fd, int timeout_ms) {
    struct pollfd pfd;
    pfd.fd = fd;
    pfd.events = POLLIN;
    int rc = poll(&pfd, 1, timeout_ms);
    if (rc < 0) return -errno;
    return rc;
}

/* Close an inotify fd. */
int chez_inotify_close(int fd) {
    return close(fd);
}

/* --- Event parsing helpers --- */

/* Get the size of struct inotify_event (without name). */
int chez_inotify_event_base_size(void) {
    return sizeof(struct inotify_event);
}

/* Extract wd from event at offset in buffer. */
int chez_inotify_event_wd(unsigned char *buf, int offset) {
    return ((struct inotify_event *)(buf + offset))->wd;
}

/* Extract mask from event at offset. */
unsigned int chez_inotify_event_mask(unsigned char *buf, int offset) {
    return ((struct inotify_event *)(buf + offset))->mask;
}

/* Extract cookie from event at offset. */
unsigned int chez_inotify_event_cookie(unsigned char *buf, int offset) {
    return ((struct inotify_event *)(buf + offset))->cookie;
}

/* Extract name length from event at offset. */
unsigned int chez_inotify_event_len(unsigned char *buf, int offset) {
    return ((struct inotify_event *)(buf + offset))->len;
}

/* Get pointer to name string (may be empty). */
const char *chez_inotify_event_name(unsigned char *buf, int offset) {
    struct inotify_event *ev = (struct inotify_event *)(buf + offset);
    if (ev->len == 0) return "";
    return ev->name;
}

/* Get total size of event at offset (header + name). */
int chez_inotify_event_size(unsigned char *buf, int offset) {
    struct inotify_event *ev = (struct inotify_event *)(buf + offset);
    return sizeof(struct inotify_event) + ev->len;
}

/* Constants */
unsigned int chez_IN_ACCESS(void)        { return IN_ACCESS; }
unsigned int chez_IN_ATTRIB(void)        { return IN_ATTRIB; }
unsigned int chez_IN_CLOSE_WRITE(void)   { return IN_CLOSE_WRITE; }
unsigned int chez_IN_CLOSE_NOWRITE(void) { return IN_CLOSE_NOWRITE; }
unsigned int chez_IN_CREATE(void)        { return IN_CREATE; }
unsigned int chez_IN_DELETE(void)        { return IN_DELETE; }
unsigned int chez_IN_DELETE_SELF(void)   { return IN_DELETE_SELF; }
unsigned int chez_IN_MODIFY(void)        { return IN_MODIFY; }
unsigned int chez_IN_MOVE_SELF(void)     { return IN_MOVE_SELF; }
unsigned int chez_IN_MOVED_FROM(void)    { return IN_MOVED_FROM; }
unsigned int chez_IN_MOVED_TO(void)      { return IN_MOVED_TO; }
unsigned int chez_IN_OPEN(void)          { return IN_OPEN; }
unsigned int chez_IN_ALL_EVENTS(void)    { return IN_ALL_EVENTS; }
unsigned int chez_IN_MOVE(void)          { return IN_MOVE; }
unsigned int chez_IN_CLOSE(void)         { return IN_CLOSE; }
unsigned int chez_IN_DONT_FOLLOW(void)   { return IN_DONT_FOLLOW; }
unsigned int chez_IN_EXCL_UNLINK(void)   { return IN_EXCL_UNLINK; }
unsigned int chez_IN_MASK_ADD(void)      { return IN_MASK_ADD; }
unsigned int chez_IN_ONESHOT(void)       { return IN_ONESHOT; }
unsigned int chez_IN_ONLYDIR(void)       { return IN_ONLYDIR; }
unsigned int chez_IN_IGNORED(void)       { return IN_IGNORED; }
unsigned int chez_IN_ISDIR(void)         { return IN_ISDIR; }
unsigned int chez_IN_Q_OVERFLOW(void)    { return IN_Q_OVERFLOW; }
unsigned int chez_IN_UNMOUNT(void)       { return IN_UNMOUNT; }
