#lang scribble/manual

@require[(for-label racket/base
                    "../dockerfile-dsl.rkt")]

@title{Dockerfile DSL: API Reference - Iteraciones 1-6}

@author{Proyecto Docker-Compose-Racket}

@section{Introducción}

El Dockerfile DSL es un lenguaje específico de dominio implementado en Racket para generar,
analizar y optimizar Dockerfiles de manera programática. Este DSL incluye características 
idiomáticas de Racket con capacidades avanzadas de análisis estático, optimización automática,
y templates reutilizables para aplicaciones comunes.

@bold{Características principales:}
@itemlist[@item{Sintaxis idiomática de Racket}
          @item{Templates para aplicaciones comunes (Node.js, Go)}
          @item{Análisis estático de seguridad y rendimiento}
          @item{Optimización automática de capas}
          @item{Macros de conveniencia para patrones comunes}
          @item{Detección de antipatrones}
          @item{Estimación de tamaño de imágenes}]

@section{Instalación y Uso Básico}

@subsection{Instalación}

Para usar el DSL, importe el módulo principal:

@codeblock{
#lang racket
(require "dockerfile-dsl.rkt")
}

@subsection{Primer Dockerfile}

Ejemplo básico de uso:

@codeblock{
(define my-dockerfile
  (docker-file
    (from "ubuntu:latest")
    (workdir "/app")
    (run "apt-get update")
    (copy "." "./")))

(displayln (docker-file->string my-dockerfile))
}

@section{ITERACIÓN 1: Comandos Básicos}

@subsection{Constructor Principal}

@defproc[(docker-file [commands dockerfile-command?] ...) dockerfile?]{
  Construye un Dockerfile a partir de una secuencia de comandos.
}

@defproc[(docker-file->string [df dockerfile?]) string?]{
  Convierte un Dockerfile a su representación en string.
}

@subsection{Comandos Fundamentales}

@defproc[(from [image string?]) dockerfile-command?]{
  Especifica la imagen base del Dockerfile.
  
  @codeblock{
    (from "ubuntu:20.04")
    (from "node:18-alpine")
  }
}

@defproc[(from/as [image string?] [stage string?]) dockerfile-command?]{
  Especifica una imagen base con nombre de stage para builds multi-etapa.
  
  @codeblock{
    (from/as "golang:1.19-alpine" "builder")
  }
}

@defproc[(workdir [path string?]) dockerfile-command?]{
  Establece el directorio de trabajo.
  
  @codeblock{
    (workdir "/app")
  }
}

@defproc[(run [command string?] ...) dockerfile-command?]{
  Ejecuta comandos durante la construcción.
  
  @codeblock{
    (run "apt-get update")
    (run "npm install")
  }
}

@defproc[(copy [source string?] [dest string?]) dockerfile-command?]{
  Copia archivos del contexto a la imagen.
  
  @codeblock{
    (copy "package.json" "./")
    (copy "src/" "./src/")
  }
}

@defproc[(copy/from [stage string?] [source string?] [dest string?]) dockerfile-command?]{
  Copia archivos desde otra stage en builds multi-etapa.
  
  @codeblock{
    (copy/from "builder" "/app/dist" "./")
  }
}

@section{ITERACIÓN 2: Comandos Extendidos}

@defproc[(env [pairs (cons/c string? string?)] ...) dockerfile-command?]{
  Define variables de entorno.
  
  @codeblock{
    (env '("NODE_ENV" . "production")
         '("PORT" . "3000"))
  }
}

@defproc[(expose [port number?]) dockerfile-command?]{
  Expone un puerto de la imagen.
  
  @codeblock{
    (expose 3000)
    (expose 8080)
  }
}

@defproc[(cmd [command string?] ...) dockerfile-command?]{
  Especifica el comando por defecto del contenedor.
  
  @codeblock{
    (cmd "npm" "start")
    (cmd "python3" "app.py")
  }
}

@defproc[(add [source string?] [dest string?]) dockerfile-command?]{
  Añade archivos con extracción automática de archivos comprimidos.
  
  @codeblock{
    (add "app.tar.gz" "/app/")
  }
}

@section{ITERACIÓN 3: Comandos con Opciones}

@defproc[(arg [name string?] [default string? #f]) dockerfile-command?]{
  Define argumentos de construcción.
  
  @codeblock{
    (arg "NODE_VERSION" "18")
    (arg "BUILD_DATE")
  }
}

@defproc[(label [pairs (cons/c string? string?)] ...) dockerfile-command?]{
  Añade metadatos a la imagen.
  
  @codeblock{
    (label '("version" . "1.0.0")
           '("maintainer" . "equipo-desarrollo"))
  }
}

@section{ITERACIÓN 4: Comandos Avanzados}

@defproc[(entrypoint [command string?] ...) dockerfile-command?]{
  Configura el punto de entrada del contenedor.
  
  @codeblock{
    (entrypoint "docker-entrypoint.sh")
    (entrypoint "python3" "-m" "myapp")
  }
}

@defproc[(volume [path string?] ...) dockerfile-command?]{
  Declara puntos de montaje de volúmenes.
  
  @codeblock{
    (volume "/data")
    (volume "/app/logs" "/app/config")
  }
}

@defproc[(user [userspec string?]) dockerfile-command?]{
  Establece el usuario para comandos subsecuentes.
  
  @codeblock{
    (user "appuser")
    (user "1001:1001")
  }
}

@defproc[(healthcheck [options string?]) dockerfile-command?]{
  Configura verificación de salud del contenedor.
  
  @codeblock{
    (healthcheck "--interval=30s --timeout=3s CMD curl -f http://localhost/health")
  }
}

@section{ITERACIÓN 5: Funciones de Orden Superior}

@subsection{Templates de Aplicaciones}

@defproc[(node-app-template [version string?] [app-name string?]) procedure?]{
  Template para aplicaciones Node.js con mejores prácticas.
  
  @codeblock{
    (define my-node-app ((node-app-template "18" "my-service")))
    (displayln (docker-file->string my-node-app))
  }
  
  Genera automáticamente:
  @itemlist[@item{FROM node:VERSION-alpine}
            @item{WORKDIR /app}  
            @item{Optimización de cache con package.json}
            @item{Configuración de producción}]
}

@defproc[(go-microservice-template [version string?] [app-name string?]) procedure?]{
  Template para microservicios Go con build multi-etapa.
  
  @codeblock{
    (define my-go-service ((go-microservice-template "api-server" "8080")))
    (displayln (docker-file->string my-go-service))
  }
  
  Incluye:
  @itemlist[@item{Build stage con dependencias}
            @item{Compilación estática optimizada}
            @item{Imagen final mínima (scratch)}
            @item{Certificados SSL incluidos}]
}

@subsection{Funciones de Composición}

@defproc[(base-image [image string?]) procedure?]{
  Función de orden superior para crear bases reutilizables.
  
  @codeblock{
    (define ubuntu-base (base-image "ubuntu:20.04"))
    (define my-app (ubuntu-base 
                     (workdir "/app")
                     (copy "." "./")))
  }
}

@defproc[(combine-dockerfiles [df1 dockerfile?] [df2 dockerfile?] ...) dockerfile?]{
  Combina múltiples Dockerfiles en uno solo.
  
  @codeblock{
    (define base-df (docker-file (from "ubuntu") (workdir "/app")))
    (define app-df (docker-file (copy "." "./") (cmd "npm" "start")))
    (define combined (combine-dockerfiles base-df app-df))
  }
}

@defproc[(optimize-layers [df dockerfile?]) dockerfile?]{
  Optimiza un Dockerfile combinando comandos RUN consecutivos.
  
  @codeblock{
    (define original (docker-file 
                       (from "alpine")
                       (run "apk add curl")
                       (run "apk add git")
                       (run "apk add python3")))
    
    (define optimized (optimize-layers original))
    ;; Combina los RUN en: RUN apk add curl && apk add git && apk add python3
  }
}

@section{ITERACIÓN 5: Macros de Conveniencia}

@defform[(with-context path body ...)]{
  Macro para establecer contexto de directorio de trabajo.
  
  @codeblock{
    (with-context "/src"
      (from "node:alpine")
      (copy "package.json" "./")
      (run "npm install"))
  }
}

@defform[(security-setup username)]{
  Macro para configuración de seguridad estándar.
  
  @codeblock{
    (security-setup "appuser")
    ;; Genera:
    ;; RUN adduser --disabled-password --gecos '' appuser
    ;; USER appuser  
  }
}

@defform[(auto-optimize body ...)]{
  Macro que aplica optimización automática a un Dockerfile.
  
  @codeblock{
    (auto-optimize
      (from "alpine")
      (run "apk add curl")
      (run "apk add git"))
    ;; Automáticamente optimiza capas RUN
  }
}

@section{ITERACIÓN 5: Análisis Avanzado}

@subsection{Análisis Completo}

@defproc[(analyze-dockerfile [df dockerfile?]) hash?]{
  Realiza análisis completo de un Dockerfile incluyendo:
  
  @itemlist[@item{Información básica (comandos, puertos, usuarios)}
            @item{Análisis de seguridad}
            @item{Análisis de rendimiento}  
            @item{Verificación de buenas prácticas}
            @item{Score de complejidad}]
  
  @codeblock{
    (define analysis (analyze-dockerfile my-dockerfile))
    (displayln analysis)
    ;; Retorna hash con análisis detallado
  }
}

@subsection{Validación de Seguridad}

@defproc[(validate-security [df dockerfile?]) hash?]{
  Valida prácticas de seguridad específicas.
  
  @codeblock{
    (define security-report (validate-security my-dockerfile))
    (hash-ref security-report 'is-secure)      ; ¿Es seguro?
    (hash-ref security-report 'issues)         ; Lista de problemas
    (hash-ref security-report 'recommendations); Recomendaciones
  }
  
  Verifica:
  @itemlist[@item{Uso de usuario no-root}
            @item{Presencia de secretos en variables}
            @item{Puertos peligrosos expuestos}
            @item{Permisos de archivos}]
}

@defproc[(detect-antipatterns [df dockerfile?]) list?]{
  Detecta antipatrones comunes en Dockerfiles.
  
  @codeblock{
    (detect-antipatterns my-dockerfile)
    ;; Retorna lista de antipatrones encontrados
  }
  
  Detecta:
  @itemlist[@item{Demasiados comandos RUN consecutivos}
            @item{Patrones de COPY muy amplios}
            @item{Falta de limpieza de cache}
            @item{Múltiples imágenes base sin multi-stage}]
}

@subsection{Estimación de Recursos}

@defproc[(estimate-dockerfile-size [df dockerfile?]) number?]{
  Estima el tamaño final de la imagen en MB.
  
  @codeblock{
    (estimate-dockerfile-size my-dockerfile)
    ;; Retorna estimación en MB basada en:
    ;; - Tamaño de imagen base
    ;; - Paquetes instalados  
    ;; - Sobrecarga de capas
  }
}

@defproc[(dockerfile-complexity-score [df dockerfile?]) number?]{
  Calcula un score de complejidad (0-100).
  
  @codeblock{
    (dockerfile-complexity-score my-dockerfile)
    ;; Considera:
    ;; - Número de comandos
    ;; - Multi-stage builds
    ;; - Comandos complejos
    ;; - Variables y argumentos
  }
}

@section{ITERACIÓN 6: Ejemplos de Producción}

@subsection{API REST Node.js Optimizada}

@codeblock{
(define rest-api-dockerfile
  (docker-file
    ;; Build stage
    (from/as "node:18-alpine" "builder")
    (workdir "/build")
    (copy "package*.json" "./")
    (run "npm ci --only=production")
    
    ;; Production stage  
    (from "node:18-alpine")
    (workdir "/app")
    (copy/from "builder" "/build/node_modules" "./node_modules")
    (copy "src/" "./src/")
    (expose 3000)
    (user "node")
    (cmd "node" "src/index.js")))
}

@subsection{Microservicio Go}

@codeblock{
(define go-microservice
  (docker-file
    ;; Build stage
    (from/as "golang:1.19-alpine" "builder")
    (workdir "/build")
    (copy "go.mod" "./")
    (copy "go.sum" "./")
    (run "go mod download")
    (copy "." "./")
    (run "CGO_ENABLED=0 GOOS=linux go build -o main .")
    
    ;; Production stage
    (from "alpine:latest")
    (run "apk --no-cache add ca-certificates")
    (workdir "/root/")
    (copy/from "builder" "/build/main" "./")
    (expose 8080)
    (cmd "./main")))
}

@section{Utilidades y Validaciones}

@defproc[(validate-dockerfile-structure [df dockerfile?]) list?]{
  Valida la estructura básica del Dockerfile.
}

@defproc[(suggest-optimizations [df dockerfile?]) list?]{
  Sugiere optimizaciones específicas para el Dockerfile.
}

@defproc[(generate-security-report [df dockerfile?]) hash?]{
  Genera reporte detallado de seguridad.
}

@section{Herramientas CLI}

El DSL incluye herramientas de línea de comandos para:

@itemlist[@item{Validación de Dockerfiles}
          @item{Análisis de seguridad}
          @item{Generación de reportes}
          @item{Optimización automática}]

@codeblock{
racket tools/dockerfile-cli.rkt validate my-dockerfile.rkt
racket tools/dockerfile-cli.rkt analyze my-dockerfile.rkt
racket tools/dockerfile-cli.rkt optimize my-dockerfile.rkt
}

@section{Ejemplos Completos}

Vea los archivos en @code{examples/} para casos de uso completos:

@itemlist[@item{@code{basic-example.rkt} - Uso básico}
          @item{@code{iteration-4-example.rkt} - Comandos avanzados}
          @item{@code{production-examples.rkt} - Casos de producción}
          @item{@code{complete-demo.rkt} - Demostración completa}]
  Establece variables de entorno.

  @codeblock{
    (env '("NODE_ENV" . "production") '("PORT" . "3000"))
  }
}

@defproc[(expose [ports number?] ...) dockerfile-command?]{
  Documenta los puertos que expone el contenedor.

  @codeblock{
    
    (expose 80)
    (expose 8080 8443)
  }
}

@defproc[(cmd [args string?] ...) dockerfile-command?]{
  Especifica el comando por defecto a ejecutar.

  @codeblock{
    
    (cmd "npm" "start")
    (cmd "/usr/local/bin/myapp")
  }
}

@section{Características Avanzadas (Iteración 5)}

@subsection{Funciones de Orden Superior}

El DSL incluye funciones de orden superior para crear patrones reutilizables:

@defproc[(base-image [image string?]) (-> dockerfile-command? ... dockerfile?)]{
  Crea una función que genera Dockerfiles con una imagen base específica.

  @codeblock{
    
    (define ubuntu-base (base-image "ubuntu:latest"))
    (ubuntu-base
      (workdir "/app")
      (run "apt-get update"))
  }
}

@defproc[(node-app-template [version string?] [app-name string?])
         (-> dockerfile-command? ... dockerfile?)]{
  Template preconfigurado para aplicaciones Node.js.

  @codeblock{
    
    (define my-node-app (node-app-template "18" "my-service"))
    (my-node-app
      (user "node")
      (cmd "npm" "start"))
  }
}

@defproc[(go-microservice-template [version string?] [app-name string?])
         (-> dockerfile-command? ... dockerfile?)]{
  Template para microservicios Go con build multi-stage.

  @codeblock{
    
    (define my-service (go-microservice-template "1.22" "auth-service"))
    (my-service (expose 8080))
  }
}

@subsection{Optimización}

@defproc[(optimize-layers [df dockerfile?]) dockerfile?]{
  Optimiza un Dockerfile combinando comandos RUN consecutivos para reducir capas.

  @codeblock{
    
    (define original
      (docker-file
        (from "ubuntu")
        (run "apt-get update")
        (run "apt-get install curl")
        (run "apt-get clean")))

    (optimize-layers original)
  }
}

@defproc[(analyze-dockerfile [df dockerfile?]) hash?]{
  Realiza un análisis completo del Dockerfile incluyendo seguridad, performance y mejores prácticas.

  @codeblock{
    
    (define test-df
      (docker-file
        (from "ubuntu")
        (run "apt-get update")
        (expose 22)))

    (analyze-dockerfile test-df)
  }
}

@section{Macros de Conveniencia}

@defform[(with-context workdir-path body ...)]{
  Establece un directorio de trabajo y ejecuta comandos en ese contexto.

  @codeblock{
    
    (with-context "/app"
      (copy "package.json" "./")
      (run "npm install"))
  }
}

@defform[(security-setup username)]{
  Configura un usuario no-root para mayor seguridad.

  @codeblock{
    
    (security-setup "appuser")
  }
}

@defform[(auto-optimize body ...)]{
  Aplica optimización automática a un conjunto de comandos.

  @codeblock{
    
    (auto-optimize
      (from "ubuntu")
      (run "apt-get update")
      (run "apt-get install curl"))
  }
}

@section{Análisis y Validación}

@subsection{Análisis de Seguridad}

@defproc[(validate-security [df dockerfile?]) (listof hash?)]{
  Analiza un Dockerfile en busca de problemas de seguridad.

  @codeblock{
    
    (define insecure-df
      (docker-file
        (from "ubuntu")
        (expose 22)
        (env '("PASSWORD" . "secret123"))))

    (validate-security insecure-df)
  }
}

@defproc[(generate-security-report [df dockerfile?]) hash?]{
  Genera un reporte completo de seguridad con resumen y recomendaciones.
}

@subsection{Análisis de Performance}

@defproc[(estimate-image-size [df dockerfile?]) number?]{
  Estima el tamaño de la imagen resultante en MB.
}

@defproc[(dockerfile-complexity-score [df dockerfile?]) number?]{
  Calcula un score de complejidad del 1 al 100.
}

@section{Ejemplos Completos}

@subsection{Aplicación Node.js de Producción}

@codeblock{
(define nodejs-production
  ((node-app-template "18" "my-service")
   ;; Security setup
   (security-setup "node")

   ;; Install dependencies first for better caching
   (copy "package*.json" "./")
   (run "npm ci --only=production")

   ;; Copy source code
   (copy "src/" "/app/src/")

   ;; Runtime configuration
   (env '("NODE_ENV" . "production")
        '("PORT" . "3000"))
   (expose 3000)

   ;; Health check
   (run "npm install -g node-healthcheck")

   ;; Start command
   (cmd "npm" "start")))

(displayln (docker-file->string nodejs-production))
}

@subsection{Microservicio Go Multi-stage}

@codeblock{
(define go-microservice
  ((go-microservice-template "1.22" "auth-service")
   ;; Expose API port
   (expose 8080)

   ;; Add health check endpoint
   (env '("HEALTH_CHECK_PORT" . "8081"))
   (expose 8081)))

;; Análisis del resultado
(define analysis (analyze-dockerfile go-microservice))
(define security-report (generate-security-report go-microservice))

(printf "Complexity Score: ~a\n" (dockerfile-complexity-score go-microservice))
(printf "Security Issues: ~a\n"
        (hash-ref (hash-ref security-report 'summary) 'total-issues))
}

@section{Mejores Prácticas}

@subsection{Optimización de Capas}

Siempre use la función @racket[optimize-layers] o la macro @racket[auto-optimize]
para reducir el número de capas en sus imágenes:

@codeblock{
;; Malo - muchas capas
(docker-file
  (from "ubuntu")
  (run "apt-get update")
  (run "apt-get install curl")
  (run "apt-get install git")
  (run "apt-get clean"))

;; Bueno - optimizado automáticamente
(auto-optimize
  (from "ubuntu")
  (run "apt-get update")
  (run "apt-get install curl")
  (run "apt-get install git")
  (run "apt-get clean"))
}

@subsection{Seguridad}

Siempre incluya configuración de seguridad:

@codeblock{
;; Template básico con seguridad
(define secure-app
  (docker-file
    (from "alpine:latest")

    ;; Install dependencies
    (run "apk add --no-cache curl")

    ;; Security setup
    (security-setup "appuser")

    ;; Application setup
    (workdir "/app")
    (copy "app" "/app/")

    ;; Expose only necessary ports
    (expose 8080)

    (cmd "/app/myapp")))
}

@subsection{Análisis Continuo}

Incluya análisis en su proceso de desarrollo:

@codeblock{
(define my-dockerfile (docker-file ...))

;; Verificar antes de hacer build
(define issues (suggest-improvements my-dockerfile))
(unless (null? issues)
  (printf "Issues found:\n")
  (for ([issue issues])
    (printf "- ~a\n" (hash-ref issue 'message))))

;; Generar reporte de seguridad
(define security-report (generate-security-report my-dockerfile))
(printf "Security Report: ~a\n" security-report)
}
