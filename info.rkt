#lang info

(define collection "dockerfile-dsl")
(define deps '("base" "scribble-lib"))
(define build-deps '("racket-doc" "rackunit-lib"))
(define scribblings '(("docs/api-reference.scrbl" ())))
(define pkg-desc "Dockerfile DSL - Lenguaje específico de dominio para generar y analizar Dockerfiles")
(define version "1.0")
(define pkg-authors '("Proyecto Docker-Compose-Racket"))
(define license '(Apache-2.0 OR MIT))
