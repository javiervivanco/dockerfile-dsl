#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo básico de la Iteración 5: Características idiomáticas

;; Template Node.js
(define node-app ((node-app-template "18" "my-service")))
(displayln "=== Template Node.js ===")
(displayln (docker-file->string node-app))

;; Template Go Microservice  
(define go-service ((go-microservice-template "api-server" "8080")))
(displayln "\n=== Template Go Microservice ===")
(displayln (docker-file->string go-service))

;; Optimización de capas
(define unoptimized (docker-file
                      (from "alpine")
                      (run "apk add curl")
                      (run "apk add git")
                      (run "apk add python3")))

(define optimized (optimize-layers unoptimized))
(displayln "\n=== Optimización de Capas ===")
(displayln "ANTES:")
(displayln (docker-file->string unoptimized))
(displayln "\nDESPUÉS:")
(displayln (docker-file->string optimized))