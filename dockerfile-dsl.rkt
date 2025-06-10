#lang racket/base

(require "private/dockerfile-core.rkt"
         "private/dockerfile-ir.rkt"
         "private/dockerfile-formatter.rkt"
         "private/dockerfile-commands.rkt"
         "private/dockerfile-validation.rkt"
         "private/dockerfile-higher-order.rkt"
         "private/dockerfile-macros.rkt"
         "private/dockerfile-analysis.rkt")

(provide ;; Estructuras principales
         dockerfile
         dockerfile-command
         dockerfile-command-type
         dockerfile-command-options
         dockerfile-command-args
         dockerfile-commands

         ;; Constructor principal
         docker-file
         docker-file->string

         ;; Comandos básicos
         from
         from/as
         workdir
         copy
         run

         ;; Comandos extendidos (Iteración 2)
         env
         expose
         cmd
         add

         ;; Comandos con opciones (Iteración 3)
         copy/from
         run/mount
         arg
         label

         ;; Comandos avanzados (Iteración 4)
         entrypoint
         volume
         user
         healthcheck

         ;; Utilidades
         empty-dockerfile
         validate-dockerfile-structure
         dockerfile->ir-list
         
         ;; === ITERACIÓN 5: FUNCIONES DE ORDEN SUPERIOR ===
         base-image
         with-workdir
         with-user
         with-env
         nodejs-base
         python-base
         golang-build-base
         compose-stages
         apply-pattern
         node-app-template
         go-microservice-template
         combine-dockerfiles
         dockerfile-pipeline
         optimize-layers
         cached-analyze

         ;; === ITERACIÓN 5: MACROS DE CONVENIENCIA ===
         with-stage
         multi-stage
         with-context
         install-packages
         security-setup
         copy-pattern
         auto-optimize
         optimize-runs
         define-dockerfile
         docker-compose

         ;; === ITERACIÓN 5: ANÁLISIS AVANZADO ===
         analyze-dockerfile
         validate-security
         estimate-image-size
         generate-security-report
         dockerfile-complexity-score
         suggest-improvements
         validate-security-practices
         detect-antipatterns
         estimate-dockerfile-size

         ;; === ITERACIÓN 4: VALIDACIONES AVANZADAS ===
         validate-dockerfile-advanced
         validate-multistage-dependencies
         check-stage-references
         suggest-optimizations)

;; === FUNCIONES PRINCIPALES ===
;; Las funciones principales están definidas en dockerfile-core.rkt

;; Conversión de Dockerfile a string
(define (docker-file->string df)
  (dockerfile->string df))
