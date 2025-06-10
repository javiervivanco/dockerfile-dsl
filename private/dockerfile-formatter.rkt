#lang racket/base

(require racket/string
         racket/list
         "dockerfile-core.rkt"
         "dockerfile-options.rkt")

(provide dockerfile->string
         format-command
         format-options
         escape-dockerfile-string)

;; Convertir un Dockerfile completo a string
(define (dockerfile->string df)
  (define formatted-commands
    (map format-command (dockerfile-commands df)))
  (string-join formatted-commands "\n"))

;; Formatear un comando individual
(define (format-command cmd)
  (define type (dockerfile-command-type cmd))
  (define type-str (string-upcase (symbol->string type)))
  (define options (dockerfile-command-options cmd))
  (define args (dockerfile-command-args cmd))

  (cond
    ;; CMD con exec form (JSON array)
    [(and (eq? type 'cmd) (assoc 'exec-form options))
     (define json-args (format "[~a]"
                               (string-join
                                (map (lambda (arg) (format "\"~a\"" arg)) args)
                                ", ")))
     (format "~a ~a" type-str json-args)]

    ;; ENV con múltiples pares
    [(eq? type 'env)
     (format "~a ~a" type-str (string-join args " "))]

    ;; EXPOSE con múltiples puertos
    [(eq? type 'expose)
     (format "~a ~a" type-str (string-join args " "))]

    ;; COPY con --from
    [(and (eq? type 'copy) (assoc 'from options))
     (define from-stage (cdr (assoc 'from options)))
     (format "~a --from=~a ~a" type-str from-stage (string-join args " "))]

    ;; RUN con --mount
    [(and (eq? type 'run) (assoc 'mount options))
     (define mount-spec (cdr (assoc 'mount options)))
     (define mount-str (format-mount-option mount-spec))
     (format "~a --mount=~a ~a" type-str mount-str (string-join args " "))]

    ;; LABEL con múltiples etiquetas
    [(eq? type 'label)
     (format "~a ~a" type-str (string-join args " "))]

    ;; ARG básico
    [(eq? type 'arg)
     (format "~a ~a" type-str (string-join args " "))]

    ;; FROM con AS
    [(and (eq? type 'from) (assoc 'as options))
     (define stage-name (cdr (assoc 'as options)))
     (format "~a ~a AS ~a" type-str (string-join args " ") stage-name)]

    ;; ENTRYPOINT con exec form (JSON array)
    [(and (eq? type 'entrypoint) (assoc 'exec-form options))
     (define json-args (format "[~a]"
                               (string-join
                                (map (lambda (arg) (format "\"~a\"" arg)) args)
                                ", ")))
     (format "~a ~a" type-str json-args)]

    ;; VOLUME con JSON array
    [(and (eq? type 'volume) (assoc 'json-array options))
     (define json-args (format "[~a]"
                               (string-join
                                (map (lambda (arg) (format "\"~a\"" arg)) args)
                                ", ")))
     (format "~a ~a" type-str json-args)]

    ;; USER básico
    [(eq? type 'user)
     (format "~a ~a" type-str (string-join args " "))]

    ;; HEALTHCHECK básico
    [(eq? type 'healthcheck)
     (format "~a ~a" type-str (string-join args " "))]

    ;; Comando estándar
    [else
     (define options-str (format-options options))
     (define args-str (string-join args " "))
     (string-trim
      (string-join (filter non-empty-string? (list type-str options-str args-str)) " "))]))

;; Formatear opciones (e.g., --from=builder)
(define (format-options options)
  (if (empty? options)
      ""
      (string-join
       (map (lambda (opt)
              (cond
                [(pair? opt)
                 (format "--~a=~a" (car opt) (cdr opt))]
                [else
                 (format "--~a" opt)]))
            options)
       " ")))

;; Verificar si una string está vacía
(define (non-empty-string? s)
  (and (string? s) (not (string=? s ""))))

;; Escapar strings que contengan caracteres especiales
(define (escape-dockerfile-string s)
  (cond
    [(regexp-match? #rx"[ \t\n\"']" s)
     (format "\"~a\"" (string-replace s "\"" "\\\""))]
    [else s]))
