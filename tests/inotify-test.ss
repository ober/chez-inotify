#!chezscheme
;;; inotify-test.ss — Tests for chez-inotify

(import (chezscheme) (chez-inotify))

(define pass-count 0)
(define fail-count 0)

(define-syntax chk
  (syntax-rules (=>)
    [(_ expr => expected)
     (let ([result expr] [exp expected])
       (if (equal? result exp)
         (set! pass-count (+ pass-count 1))
         (begin (set! fail-count (+ fail-count 1))
                (display "FAIL: ") (write 'expr)
                (display " => ") (write result)
                (display " expected ") (write exp) (newline))))]))

;;; Constants
(chk (> IN_CREATE 0) => #t)
(chk (> IN_DELETE 0) => #t)
(chk (> IN_MODIFY 0) => #t)
(chk (> IN_ALL_EVENTS 0) => #t)
(chk (> IN_ISDIR 0) => #t)

;;; Create and close
(let ([fd (inotify-init)])
  (chk (> fd 0) => #t)
  (inotify-close fd))

;;; Watch a temp directory, create a file, read events
(let ([dir (format "/tmp/chez-inotify-test-~a" (random 1000000))])
  (mkdir dir)
  (let ([fd (inotify-init)])
    (let ([wd (inotify-add-watch fd dir (bitwise-ior IN_CREATE IN_DELETE))])
      (chk (>= wd 0) => #t)

      ;; Create a file in the watched directory
      (let ([test-file (format "~a/testfile.txt" dir)])
        (call-with-output-file test-file
          (lambda (p) (display "hello" p)))

        ;; Poll for events (should be ready)
        (chk (inotify-poll fd 100) => #t)

        ;; Read events
        (let ([events (inotify-read-events fd)])
          (chk (> (length events) 0) => #t)
          (let ([ev (car events)])
            (chk (= (inotify-event-wd ev) wd) => #t)
            (chk (> (bitwise-and (inotify-event-mask ev) IN_CREATE) 0) => #t)
            (chk (equal? (inotify-event-name ev) "testfile.txt") => #t)))

        ;; Delete the file
        (delete-file test-file)

        ;; Read delete event
        (when (inotify-poll fd 100)
          (let ([events (inotify-read-events fd)])
            (chk (> (length events) 0) => #t)
            (let ([ev (car events)])
              (chk (> (bitwise-and (inotify-event-mask ev) IN_DELETE) 0) => #t)))))

      ;; Remove watch and close
      (inotify-rm-watch fd wd))
    (inotify-close fd))
  ;; Cleanup
  (delete-directory dir #f))

;;; No events available — returns empty list
(let ([dir (format "/tmp/chez-inotify-test2-~a" (random 1000000))])
  (mkdir dir)
  (let ([fd (inotify-init)])
    (inotify-add-watch fd dir IN_CREATE)
    (chk (inotify-poll fd 0) => #f)  ;; no events
    (chk (null? (inotify-read-events fd)) => #t)
    (inotify-close fd))
  (delete-directory dir #f))

;;; Summary
(newline)
(display "inotify tests: ")
(display pass-count) (display " passed, ")
(display fail-count) (display " failed")
(newline)
(when (> fail-count 0) (exit 1))
