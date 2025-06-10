#lang racket/base

(require rackunit
         racket/string
         "../dockerfile-dsl.rkt")

;; Pruebas básicas para la Iteración 5

(define iteration-5-tests
  (test-suite
   "Iteración 5: Características idiomáticas"
   
   (test-case "Template Node.js funciona"
     (define template (node-app-template "18" "test-app"))
     (define app (template))
     (check-true (dockerfile app))
     (check-true (string-contains? (docker-file->string app) "FROM node:18-alpine")))
   
   (test-case "Template Go funciona"
     (define template (go-microservice-template "test-service" "3000"))
     (define service (template))
     (check-true (dockerfile service))
     (check-true (string-contains? (docker-file->string service) "FROM golang")))
   
   (test-case "Optimización de capas funciona"
     (define original (docker-file
                        (from "alpine")
                        (run "apk add curl")
                        (run "apk add git")))
     (define optimized (optimize-layers original))
     (check-true (dockerfile optimized))
     (define optimized-str (docker-file->string optimized))
     (check-true (string-contains? optimized-str "&&")))))

(run-tests iteration-5-tests)