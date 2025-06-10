#lang racket/base

(require racket/contract)

(provide (struct-out dockerfile-command)
         (struct-out dockerfile)
         dockerfile-command?
         dockerfile?
         dockerfile-command-type
         dockerfile-command-options
         dockerfile-command-args
         dockerfile-commands
         ;; Funciones principales
         docker-file)

;; Representación intermedia básica para comandos individuales
;; type: símbolo que identifica el tipo de comando (e.g., 'from, 'workdir)
;; options: lista de opciones/flags (e.g., '((from . "builder")))
;; args: lista de argumentos del comando
(struct dockerfile-command (type options args) #:transparent)

;; Estructura para el Dockerfile completo
;; commands: lista de dockerfile-command structs
(struct dockerfile (commands) #:transparent)

;; Contratos para validación
(define dockerfile-command-contract
  (struct/c dockerfile-command
            symbol?
            (listof pair?)
            (listof string?)))

(define dockerfile-contract
  (struct/c dockerfile
            (listof dockerfile-command?)))

;; Constructor principal del DSL
;; Uso: (docker-file (from "ubuntu") (workdir "/app") ...)
(define (docker-file . commands)
  (dockerfile commands))
