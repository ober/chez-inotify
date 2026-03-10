#!chezscheme
;;; chez-inotify — Linux inotify for Chez Scheme

(library (chez-inotify)
  (export
    ;; Core API
    inotify-init inotify-close
    inotify-add-watch inotify-rm-watch
    inotify-read-events inotify-poll
    ;; Event record
    make-inotify-event inotify-event?
    inotify-event-wd inotify-event-mask
    inotify-event-cookie inotify-event-name
    ;; Constants — watch masks
    IN_ACCESS IN_ATTRIB IN_CLOSE_WRITE IN_CLOSE_NOWRITE
    IN_CREATE IN_DELETE IN_DELETE_SELF IN_MODIFY
    IN_MOVE_SELF IN_MOVED_FROM IN_MOVED_TO IN_OPEN
    IN_ALL_EVENTS IN_MOVE IN_CLOSE
    ;; Constants — watch flags
    IN_DONT_FOLLOW IN_EXCL_UNLINK IN_MASK_ADD IN_ONESHOT IN_ONLYDIR
    ;; Constants — event flags
    IN_IGNORED IN_ISDIR IN_Q_OVERFLOW IN_UNMOUNT)

  (import (chezscheme))

  ;; Load the C shim
  (define _loaded (load-shared-object "chez_inotify_shim.so"))

  ;; ---- FFI bindings ----
  (define c-init       (foreign-procedure "chez_inotify_init" () int))
  (define c-add-watch  (foreign-procedure "chez_inotify_add_watch" (int string unsigned-int) int))
  (define c-rm-watch   (foreign-procedure "chez_inotify_rm_watch" (int int) int))
  (define c-read       (foreign-procedure "chez_inotify_read" (int u8* int) int))
  (define c-poll       (foreign-procedure "chez_inotify_poll" (int int) int))
  (define c-close      (foreign-procedure "chez_inotify_close" (int) int))
  (define c-event-wd     (foreign-procedure "chez_inotify_event_wd" (u8* int) int))
  (define c-event-mask   (foreign-procedure "chez_inotify_event_mask" (u8* int) unsigned-int))
  (define c-event-cookie (foreign-procedure "chez_inotify_event_cookie" (u8* int) unsigned-int))
  (define c-event-name   (foreign-procedure "chez_inotify_event_name" (u8* int) string))
  (define c-event-size   (foreign-procedure "chez_inotify_event_size" (u8* int) int))

  ;; ---- Constants ----
  (define IN_ACCESS        ((foreign-procedure "chez_IN_ACCESS" () unsigned-int)))
  (define IN_ATTRIB        ((foreign-procedure "chez_IN_ATTRIB" () unsigned-int)))
  (define IN_CLOSE_WRITE   ((foreign-procedure "chez_IN_CLOSE_WRITE" () unsigned-int)))
  (define IN_CLOSE_NOWRITE ((foreign-procedure "chez_IN_CLOSE_NOWRITE" () unsigned-int)))
  (define IN_CREATE        ((foreign-procedure "chez_IN_CREATE" () unsigned-int)))
  (define IN_DELETE        ((foreign-procedure "chez_IN_DELETE" () unsigned-int)))
  (define IN_DELETE_SELF   ((foreign-procedure "chez_IN_DELETE_SELF" () unsigned-int)))
  (define IN_MODIFY        ((foreign-procedure "chez_IN_MODIFY" () unsigned-int)))
  (define IN_MOVE_SELF     ((foreign-procedure "chez_IN_MOVE_SELF" () unsigned-int)))
  (define IN_MOVED_FROM    ((foreign-procedure "chez_IN_MOVED_FROM" () unsigned-int)))
  (define IN_MOVED_TO      ((foreign-procedure "chez_IN_MOVED_TO" () unsigned-int)))
  (define IN_OPEN          ((foreign-procedure "chez_IN_OPEN" () unsigned-int)))
  (define IN_ALL_EVENTS    ((foreign-procedure "chez_IN_ALL_EVENTS" () unsigned-int)))
  (define IN_MOVE          ((foreign-procedure "chez_IN_MOVE" () unsigned-int)))
  (define IN_CLOSE         ((foreign-procedure "chez_IN_CLOSE" () unsigned-int)))
  (define IN_DONT_FOLLOW   ((foreign-procedure "chez_IN_DONT_FOLLOW" () unsigned-int)))
  (define IN_EXCL_UNLINK   ((foreign-procedure "chez_IN_EXCL_UNLINK" () unsigned-int)))
  (define IN_MASK_ADD      ((foreign-procedure "chez_IN_MASK_ADD" () unsigned-int)))
  (define IN_ONESHOT       ((foreign-procedure "chez_IN_ONESHOT" () unsigned-int)))
  (define IN_ONLYDIR       ((foreign-procedure "chez_IN_ONLYDIR" () unsigned-int)))
  (define IN_IGNORED       ((foreign-procedure "chez_IN_IGNORED" () unsigned-int)))
  (define IN_ISDIR         ((foreign-procedure "chez_IN_ISDIR" () unsigned-int)))
  (define IN_Q_OVERFLOW    ((foreign-procedure "chez_IN_Q_OVERFLOW" () unsigned-int)))
  (define IN_UNMOUNT       ((foreign-procedure "chez_IN_UNMOUNT" () unsigned-int)))

  ;; ---- Error handling ----
  (define (check-rc who rc)
    (when (< rc 0)
      (error who (format "errno ~a" (- rc)))))

  ;; ---- Event record ----
  (define-record-type inotify-event
    (fields wd mask cookie name))

  ;; ---- Public API ----

  ;; Create an inotify instance. Returns fd.
  (define (inotify-init)
    (let ([rc (c-init)])
      (check-rc 'inotify-init rc)
      rc))

  ;; Close an inotify fd.
  (define (inotify-close fd)
    (c-close fd))

  ;; Add a watch on path with event mask. Returns watch descriptor.
  (define (inotify-add-watch fd path mask)
    (let ([rc (c-add-watch fd path mask)])
      (check-rc 'inotify-add-watch rc)
      rc))

  ;; Remove a watch by descriptor.
  (define (inotify-rm-watch fd wd)
    (let ([rc (c-rm-watch fd wd)])
      (check-rc 'inotify-rm-watch rc)))

  ;; Poll for readability. timeout-ms: -1 = block, 0 = poll, >0 = ms.
  ;; Returns #t if data available, #f if timeout.
  (define (inotify-poll fd timeout-ms)
    (let ([rc (c-poll fd timeout-ms)])
      (check-rc 'inotify-poll rc)
      (> rc 0)))

  ;; Read all pending events. Returns list of inotify-event records.
  ;; If no events available, returns '().
  (define (inotify-read-events fd)
    (let ([buf (make-bytevector 4096 0)])
      (let ([n (c-read fd buf 4096)])
        (check-rc 'inotify-read-events n)
        (if (= n 0) '()
          (let loop ([offset 0] [events '()])
            (if (>= offset n) (reverse events)
              (let ([ev (make-inotify-event
                          (c-event-wd buf offset)
                          (c-event-mask buf offset)
                          (c-event-cookie buf offset)
                          (let ([name (c-event-name buf offset)])
                            (if (string=? name "") #f name)))]
                    [sz (c-event-size buf offset)])
                (loop (+ offset sz) (cons ev events)))))))))

  ) ;; end library
