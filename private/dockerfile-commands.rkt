#lang racket/base

(require racket/list
         racket/string
         "dockerfile-core.rkt"
         "dockerfile-ir.rkt"
         "dockerfile-options.rkt")

(provide from
         from/as
         workdir
         copy
         copy/from
         run
         run/mount
         env
         expose
         cmd
         add
         arg
         label
         entrypoint
         volume
         user
         healthcheck)

;; FROM comando
;; Uso: (from "ubuntu:latest") o (from "node" "18-alpine")
(define (from image . args)
  (cond
    [(empty? args)
     (make-dockerfile-command 'from '() (list image))]
    [else
     (define tag (first args))
     (make-dockerfile-command 'from '() (list (format "~a:~a" image tag)))]))

;; FROM con AS para multi-stage builds
;; Uso: (from/as "golang:1.22" "builder")
(define (from/as image stage-name)
  (make-dockerfile-command 'from
                           (list (cons 'as stage-name))
                           (list image)))

;; WORKDIR comando
;; Uso: (workdir "/app")
(define (workdir path)
  (make-dockerfile-command 'workdir '() (list path)))

;; COPY comando básico
;; Uso: (copy "src/" "dest/")
(define (copy source dest)
  (make-dockerfile-command 'copy '() (list source dest)))

;; COPY con opción --from (multi-stage builds)
;; Uso: (copy/from "builder" "/app/bin" "/usr/local/bin/")
(define (copy/from stage source dest)
  (make-dockerfile-command 'copy
                           (list (cons 'from stage))
                           (list source dest)))

;; RUN comando - soporta múltiples comandos
;; Uso: (run "apt-get update") o (run "apt-get update" "apt-get install -y curl")
(define (run . commands)
  (cond
    [(= (length commands) 1)
     (make-dockerfile-command 'run '() (list (first commands)))]
    [else
     (define joined-commands (string-join commands " && "))
     (make-dockerfile-command 'run '() (list joined-commands))]))

;; RUN con opción --mount
;; Uso: (run/mount '((type . "bind") (source . ".") (target . "/app")) "go build")
(define (run/mount mount-spec . commands)
  (when (not (validate-mount-spec mount-spec))
    (error "Invalid mount specification"))
  (define joined-commands
    (if (= (length commands) 1)
        (first commands)
        (string-join commands " && ")))
  (make-dockerfile-command 'run
                           (list (cons 'mount mount-spec))
                           (list joined-commands)))

;; ENV comando - soporta múltiples pares clave-valor
;; Uso: (env '("DEBUG" . "true") '("PORT" . "8080"))
(define (env . key-value-pairs)
  (define env-pairs
    (map (lambda (pair)
           (format "~a=\"~a\"" (car pair) (cdr pair)))
         key-value-pairs))
  (make-dockerfile-command 'env '() env-pairs))

;; EXPOSE comando - soporta múltiples puertos
;; Uso: (expose 80) o (expose 8080 8443)
(define (expose . ports)
  (define port-strings (map number->string ports))
  (make-dockerfile-command 'expose '() port-strings))

;; CMD comando - soporta tanto shell form como exec form
;; Uso: (cmd "npm start") o (cmd "node" "server.js")
(define (cmd . args)
  (cond
    [(= (length args) 1)
     ;; Shell form
     (make-dockerfile-command 'cmd '() (list (first args)))]
    [else
     ;; Exec form - se formateará como JSON array
     (make-dockerfile-command 'cmd '((exec-form . #t)) args)]))

;; ADD comando básico
;; Uso: (add "file.tar.gz" "/app/")
(define (add source dest)
  (make-dockerfile-command 'add '() (list source dest)))

;; ARG comando - soporta valor por defecto opcional
;; Uso: (arg "VERSION") o (arg "BUILD_DATE" "2024-01-01")
(define (arg name . args)
  (cond
    [(empty? args)
     (make-dockerfile-command 'arg '() (list name))]
    [else
     (define default-value (first args))
     (make-dockerfile-command 'arg '() (list (format "~a=~a" name default-value)))]))

;; LABEL comando - soporta múltiples etiquetas
;; Uso: (label '("version" . "1.0") '("maintainer" . "dev@example.com"))
(define (label . key-value-pairs)
  (define label-pairs
    (map (lambda (pair)
           (format "~a=\"~a\"" (car pair) (cdr pair)))
         key-value-pairs))
  (make-dockerfile-command 'label '() label-pairs))

;; ENTRYPOINT comando - soporta tanto shell form como exec form
;; Uso: (entrypoint "/app/entrypoint.sh") o (entrypoint "docker-entrypoint.sh" "postgres")
(define (entrypoint . args)
  (cond
    [(= (length args) 1)
     ;; Shell form
     (make-dockerfile-command 'entrypoint '() (list (first args)))]
    [else
     ;; Exec form - se formateará como JSON array
     (make-dockerfile-command 'entrypoint '((exec-form . #t)) args)]))

;; VOLUME comando - soporta múltiples paths
;; Uso: (volume "/data") o (volume "/var/lib/mysql" "/var/log/mysql")
(define (volume . paths)
  (make-dockerfile-command 'volume '((json-array . #t)) paths))

;; USER comando
;; Uso: (user "node") o (user "1000:1000")
(define (user user-spec)
  (make-dockerfile-command 'user '() (list user-spec)))

;; HEALTHCHECK comando
;; Uso: (healthcheck "CMD curl -f http://localhost/ || exit 1")
(define (healthcheck command)
  (make-dockerfile-command 'healthcheck '() (list command)))
