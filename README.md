# Introducción

[Apache NiFi](https://nifi.apache.org/) es una plataforma de integración de datos y automatización de flujos de trabajo diseñada para gestionar, mover y transformar datos entre sistemas diversos de manera eficiente, confiable y en tiempo real. Es un proyecto de código abierto desarrollado por la Fundación Apache, basado en el concepto de "programación por flujo". Dispone de una interfaz web que permite definir estos flujos. Por cuestiones de seguridad, se sugiere no permitir acceso directo desde clientes web a este entorno. En su lugar, se propone el uso de proxies que aislen a [Apache NiFi](https://nifi.apache.org/) del exterior. 

![NIFI](https://nifi.apache.org/images/main-hero.svg)

En este repositorio desplegamos [Apache NiFi](https://nifi.apache.org/) detrás de [Traefik](https://doc.traefik.io/traefik/). [Traefik](https://doc.traefik.io/traefik/) es un proxy inverso y balanceador de carga de código abierto diseñado específicamente para microservicios y arquitecturas modernas basadas en contenedores, como Docker, Kubernetes, y otras plataformas de orquestación. Su principal objetivo es simplificar el manejo de las rutas y el tráfico hacia las aplicaciones distribuidas.

![Traefik](https://doc.traefik.io/traefik/assets/img/traefik-architecture.png)

Para desplegar y orquestar este entorno, se hace uso de docker-compose. [Docker Compose](https://docs.docker.com/compose/) es una herramienta de Docker que permite definir y gestionar aplicaciones multicontenedor. Utiliza un archivo de configuración (generalmente llamado docker-compose.yml) para describir los servicios, redes y volúmenes necesarios para una aplicación y luego orquesta su despliegue con un solo comando.

# Instalación

Clone este repositorio ejecutando:

```bash
git clone
```

Tras clonar el repositorio, tendremos una nueva carpeta denominada `opendatalab-nifi` en la que encontraremos la siguiente
estructura de directorios:

```bash
> ls opendatalab-nifi
data docker etc enviroment_variables.env README.md setup.sh
```

En la carpeta `docker` encontraremos el fichero `docker-compose.base.yml` que define los servicios que se desplegarán. 
En la carpeta `etc` se localizan dos subcarpetas, `nifi` con la configuración de `nifi`y la subcarpeta `traefik` con
la configuración de traefik. En la carpeta `data` se almacenarán los datos generados por los contenedores.
El fichero `enviroment_variables.env` contiene un ejemplo con las distintas variables de entorno que podemos usar para
adaptar nuestro despliegue. El fichero `setup.sh` es un script que nos facilitará la gestión de nuestro despliegue.

> [!CAUTION]
> Los contenidos albergados en `data` y `etc` tienen un carácter persistente, nunca se borrarán a no ser que lo haga de  forma explícita.

# Configuración

La configuración del despliegue se realiza mediante un fichero `.env`. Puede crearlo ejecutando la siguiente sentencia:
```bash
cp enviroment_variables.env docker/.env
```
En dicho fichero no encontraremos con las siguientes opciones:

* Variables comunes
* Variable traefik
* Variables nifi

## Variables comunes

El stack se configura globalmente estableciendo las siguientes variables

* **COMPOSE_PROJECT_NAME**: Nombre con el que se creará el stack. Por fecto, `nifi-opendatalab2`.
* **COMPOSE_USER**: Usuario que ejecutará el stack. Es recomendable poner el nombre del usuario del sistema que lanzará el comando docker (`id -u`). Por defecto, `1000`.
* **COMPOSE_GRP**: Grupo del usuario que ejecutará el stack. Es recomendable poner el nombre del usuario del sistema que lanzará el comando docker (`id -g`). Por defecto, `1000`.
* **COMPOSE_NETWORKNAME**. Nombre de la red que generará el stack. Por defecto, `nifi-opendatalab2-network`.

## Variables  Taefik

La configuración de traefik se puede ajusta mediante las siguientes variables:

* **TRAEFIK_IMAGE_NAME**. Nombre de la imagen de traefik a usar, por defecto vale `traefik`.
* **TRAEFIK_ACTIVE_BRANCH**. Versión de traefik a instalar, por defecto `v3.0`.
* **TRAEFIK_NAME**. Nombre del dominio que nos dará acceso al dashoard de traefik, por defecto vale `proxy.opendatalab2.uhu.es`.
* **TRAEFIK_HTTP_PORT**. Número de puerto usado para conexiones http. Por defectom `80`.
* **TRAEFIK_HTTPS_PORT**. Número de puerto usado para conexiones https. Por defecto `443`.
* **TRAEFIK_LOG_LEVEL**. Nivel de depuración de traefik. Por defecto, `DEBUG`.
* **TRAEFIK_ENABLE_DASHBOARD**. Se activa la web de monitorización de traefik. En caso de activarla hay que protegerla con usuario y clave. Por defecto, `true`
* **TRAEFIK_ADMIN_USER**. Nombre de usuario con acceso al dashboard de traefik. Por defecto, `admin`.
* **TRAEFIK_ADMIN_PASSWORD**. Clave de usuario con accedo al dashboard de traefik. Por defecfo, `password`.

Para generar una clave para el el usuario con accedo a traefik puede ejecutar el siguiente comando:
```bash
htpasswd -nb admin password 
```
El resultado de ejecutar este comando sería:
```
admin:$apr1$sctv3w4l$THkC377MZ8QS0J5.LU20m0
```
Los valores separados por un `:` son los deberemos asociar a las variables `TRAEFIK_ADMIN_USER` y `TRAEFIK_ADMIN_PASSWORD` respectivamente. 

Si no disponemos del comando htpasswd, podemo usar el servicio web [generator](https://hostingcanada.org/htpasswd-generator/)

## Variables  Nifi

Para configurar Nifi puedo establecer distintos valores para las siguientes variables:

* **NIFI_IMAGE_NAME**. Nombre de la imagen de nifi a usar. Por defecto, `apache/nifi`.
* **NIFI_ACTIVE_BRANCH**. Versión de nifi a instalar. ^pr defecto `"2.0.0"`.
* **NIFI_NAME**. Dominio que le asociaremos a la instancia de nifi creada. Por fefecto, `nifi.opendatalab2.uhu.es`.
* **NIFI_WEB_HTTP_PORT**. Puerto para el protocolo http. Por defecto, `8080`.
* **NIFI_WEB_HTTPS_PORT**. Puerto para el protocolo https. Por defecto, `8443`.
* **NIFI_SINGLE_USER_CREDENTIALS_USERNAME**. Usuario para acceder al entorno nifi. Por defecto, `admin`.
* **NIFI_SINGLE_USER_CREDENTIALS_PASSWORD**. Clave del usuario que tiene acceso al entorno nifi. Por defecto, `ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB`.

## Ejemplo de fichero de configuración

A continuación se muestra el contenido de un posible fichero `.env`:

```ini
# Global

COMPOSE_PROJECT_NAME="nifi-opendatalab2"
COMPOSE_USER=1000
COMPOSE_GRP=1000
COMPOSE_NETWORKNAME="nifi-opendatalab2"

# Taefik

TRAEFIK_IMAGE_NAME=traefik
TRAEFIK_ACTIVE_BRANCH="v3.0"
TRAEFIK_NAME="proxy.opendatalab2.uhu.es"
TRAEFIK_HTTP_PORT="80"
TRAEFIK_HTTPS_PORT="443"
TRAEFIK_LOG_LEVEL="DEBUG"
TRAEFIK_ENABLE_DASHBOARD="true"

TRAEFIK_ADMIN_USER="admin"
TRAEFIK_ADMIN_PASSWORD='$apr1$CBkxfGFG$15w43pPGtrIDwtydX8e7O0'

# NIfi

NIFI_IMAGE_NAME=apache/nifi
NIFI_ACTIVE_BRANCH="2.0.0"
NIFI_NAME=nifi.opendatalab2.uhu.es
NIFI_WEB_HTTP_PORT=8080
NIFI_WEB_HTTPS_PORT=8443
NIFI_SINGLE_USER_CREDENTIALS_USERNAME=admin
NIFI_SINGLE_USER_CREDENTIALS_PASSWORD=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB
```

# Manual de uso

Una vez creado el fichero `.env` con la configuración de nuestro entorno, podremos: arrancar, pararlo, consultar los log y acceder, mediante shell, a los contenedores. Todas estas operaciones se pueden hacer directamente mediante ejecutando el script `setup.sh`. Puede consultar todas las opciones que proporciona ejecutardo:

```bash
./setup-sh help
```

## Arranque del stack

Para realizar el despliegue de nuestro stack ejecutamos

```bash
./setup.sh start
```

Durante este proceso, además de descargarnos las imágenes de los distintos contenedores, se procederá a crear certificados
ssl autofirmados para los valores indicados en las variables de entorno `TRAEFIK_NAME` y  `NIFI_NAME`. Si dichos
certificados ya existen no los sobreescribirá. Si desea usar sus propios certificados, deberá almacenarlos en el 
directorio `etc/traefik/certs` y los nombres deberán ser `TRAEFIK_NAME.crt`, `TRAEFIK_NAME.key`, `NIFI_NAME.crt` 
y `NIFI_NAME.key`. Esto es, en el directorio `etc/traefik/certs` deberemos tener los siguientes ficheros:

```bash
# ls etc/traefik/certs
nifi.opendatalab2.uhu.es.crt  proxy.opendatalab2.uhu.es.crt
nifi.opendatalab2.uhu.es.key  proxy.opendatalab2.uhu.es.key
``` 

Una vez finalizado el proceso de despliegue, podremos acceder a nifi en la siguiente dirección:

```
https://nifi.opendatalab2.uhu.es/
```

Donde `nifi.opendatalab2.uhu.es/` es el nombre indicado en la variable de entorno `NIFI_NAME`.

## Consulta de logs

Si, durante el proceso de despliegue, los contenedores generan mensajes de error o de warning, podemos hacer uso del siguiente comando para consultarlos:

```bash
./setup.sh logs
```

## Acceso a los contenedores

Si, por algún motivo, deseamos acceder a los conyenedores en ejecutación. Lo podemos hacer ejecutando:

``` bash
./setup.sh shell
```

En este caso no se destruyen ni los volúmenes ni las redes creadas.


## Parada del stack

Para parar nuestro stack ejecutamos

``` bash
./setup.sh stop
```

En este caso no se destruyen ni los volúmenes ni las redes creadas.



