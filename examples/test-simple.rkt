#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo simple de Iteraciones 5-6
(printf "Probando templates...\n")

;; Template Node.js básico
(define node-template (node-app-template "18" "test-app"))
(define app (node-template))
(printf "✅ Template Node.js OK\n")

;; Template Go básico
(define go-template (go-microservice-template "test" "8080"))
(define service (go-template))
(printf "✅ Template Go OK\n")

(printf "Pruebas completadas.\n")
