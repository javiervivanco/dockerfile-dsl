#lang racket/base

(require rackunit
         rackunit/text-ui
         "basic-tests.rkt"
         "iteration-2-tests.rkt"
         "iteration-3-tests.rkt")

;; Suite completa de tests para todas las iteraciones
(define all-tests
  (test-suite "DSL de Dockerfile - Suite Completa"
    basic-tests
    iteration-2-tests
    iteration-3-tests))

;; Ejecutar todas las suites de tests
(run-tests all-tests)

;; Resumen de funcionalidades implementadas
(displayln "")
(displayln "=== RESUMEN DE IMPLEMENTACIÓN ===")
(displayln "")
(displayln "✅ ITERACIÓN 1: Fundamentos Básicos")
(displayln "   - Arquitectura base con IR (Representación Intermedia)")
(displayln "   - Comandos básicos: FROM, WORKDIR, COPY, RUN")
(displayln "   - Constructor principal: docker-file")
(displayln "   - Conversión IR → string: docker-file->string")
(displayln "   - Sistema de formateo básico")
(displayln "")
(displayln "✅ ITERACIÓN 2: Comandos Extendidos")
(displayln "   - RUN con múltiples comandos (concatenación con &&)")
(displayln "   - ENV con múltiples variables de entorno")
(displayln "   - EXPOSE con múltiples puertos")
(displayln "   - CMD con shell form y exec form (JSON array)")
(displayln "   - ADD para archivos y URLs")
(displayln "   - Sistema de formateo avanzado")
(displayln "")
(displayln "✅ ITERACIÓN 3: Opciones y Flags Avanzados")
(displayln "   - COPY --from para multi-stage builds")
(displayln "   - RUN --mount para cache y bind mounts")
(displayln "   - FROM AS para nombrar stages")
(displayln "   - ARG con valores por defecto")
(displayln "   - LABEL con múltiples etiquetas")
(displayln "   - Sistema de opciones genérico")
(displayln "")
(displayln "🎯 CARACTERÍSTICAS PRINCIPALES:")
(displayln "   - DSL idiomático de Racket")
(displayln "   - Salida de strings válidos de Dockerfile")
(displayln "   - Soporte completo para multi-stage builds")
(displayln "   - Validación básica de estructura")
(displayln "   - Arquitectura extensible")
(displayln "   - Suite de tests comprehensiva")
(displayln "")
(displayln "📁 ARCHIVOS CREADOS:")
(displayln "   - dockerfile-dsl.rkt (API principal)")
(displayln "   - private/dockerfile-core.rkt (estructuras de datos)")
(displayln "   - private/dockerfile-ir.rkt (representación intermedia)")
(displayln "   - private/dockerfile-formatter.rkt (conversión a string)")
(displayln "   - private/dockerfile-commands.rkt (constructores de comandos)")
(displayln "   - private/dockerfile-options.rkt (sistema de opciones)")
(displayln "   - tests/ (suite completa de tests)")
(displayln "   - examples/ (ejemplos de uso)")
(displayln "")
(displayln "🚀 PRÓXIMOS PASOS (Iteraciones 4-6):")
(displayln "   - ENTRYPOINT, VOLUME, USER, HEALTHCHECK")
(displayln "   - Funciones de orden superior y macros")
(displayln "   - Validación avanzada y optimizaciones")
(displayln "   - Documentación con Scribble")
(displayln "")
