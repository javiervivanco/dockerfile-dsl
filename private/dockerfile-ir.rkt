#lang racket/base

(require racket/list
         racket/string
         "dockerfile-core.rkt")

(provide make-dockerfile-command
         add-command-to-dockerfile
         empty-dockerfile
         dockerfile->ir-list
         validate-dockerfile-structure)

;; Constructor conveniente para dockerfile-command
(define (make-dockerfile-command type [options '()] [args '()])
  (dockerfile-command type options args))

;; Crear un Dockerfile vacío
(define (empty-dockerfile)
  (dockerfile '()))

;; Agregar un comando a un Dockerfile existente
(define (add-command-to-dockerfile df cmd)
  (dockerfile (append (dockerfile-commands df) (list cmd))))

;; Convertir Dockerfile a lista de representación intermedia para debugging
(define (dockerfile->ir-list df)
  (map (lambda (cmd)
         (list (dockerfile-command-type cmd)
               (dockerfile-command-options cmd)
               (dockerfile-command-args cmd)))
       (dockerfile-commands df)))

;; Validación básica de estructura de Dockerfile
(define (validate-dockerfile-structure df)
  (define commands (dockerfile-commands df))
  (cond
    [(empty? commands) #t]
    [else
     (define first-cmd (first commands))
     ;; El primer comando debe ser FROM (excepto si hay ARG antes)
     (or (eq? (dockerfile-command-type first-cmd) 'from)
         (eq? (dockerfile-command-type first-cmd) 'arg))]))
