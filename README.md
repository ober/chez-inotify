# chez-inotify

Linux inotify filesystem event monitoring for Chez Scheme.

## Requirements

- Chez Scheme 10.x
- Linux (inotify is Linux-only)
- GCC

## Build

```bash
make
```

## Usage

```scheme
(import (chez-inotify))

(define fd (inotify-init))
(define wd (inotify-add-watch fd "/path/to/watch"
             (bitwise-ior IN_CREATE IN_DELETE IN_MODIFY)))

;; Poll with 5 second timeout
(when (inotify-poll fd 5000)
  (for-each
    (lambda (ev)
      (printf "wd=~a mask=~a name=~a~%"
        (inotify-event-wd ev)
        (inotify-event-mask ev)
        (inotify-event-name ev)))
    (inotify-read-events fd)))

(inotify-rm-watch fd wd)
(inotify-close fd)
```

## API

| Function | Description |
|----------|-------------|
| `(inotify-init)` | Create inotify instance, returns fd |
| `(inotify-close fd)` | Close inotify fd |
| `(inotify-add-watch fd path mask)` | Add watch, returns wd |
| `(inotify-rm-watch fd wd)` | Remove watch |
| `(inotify-poll fd timeout-ms)` | Poll for events, returns #t/#f |
| `(inotify-read-events fd)` | Read all pending events |

## Event Record

| Accessor | Description |
|----------|-------------|
| `(inotify-event-wd ev)` | Watch descriptor |
| `(inotify-event-mask ev)` | Event mask |
| `(inotify-event-cookie ev)` | Cookie for rename tracking |
| `(inotify-event-name ev)` | Filename or #f |

## Constants

Watch masks: `IN_ACCESS`, `IN_ATTRIB`, `IN_CLOSE_WRITE`, `IN_CLOSE_NOWRITE`, `IN_CREATE`, `IN_DELETE`, `IN_DELETE_SELF`, `IN_MODIFY`, `IN_MOVE_SELF`, `IN_MOVED_FROM`, `IN_MOVED_TO`, `IN_OPEN`, `IN_ALL_EVENTS`, `IN_MOVE`, `IN_CLOSE`

Watch flags: `IN_DONT_FOLLOW`, `IN_EXCL_UNLINK`, `IN_MASK_ADD`, `IN_ONESHOT`, `IN_ONLYDIR`

Event flags: `IN_IGNORED`, `IN_ISDIR`, `IN_Q_OVERFLOW`, `IN_UNMOUNT`
# chez-inotify
