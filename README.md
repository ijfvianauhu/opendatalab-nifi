# Introducción

[Apache NiFi](https://nifi.apache.org/) es una plataforma de integración de datos y automatización de flujos de trabajo diseñada para gestionar, 
mover y transformar datos entre sistemas diversos de manera eficiente, confiable y en tiempo real. Es un proyecto de código 
abierto desarrollado por la Fundación Apache, basado en el concepto de "programación por flujo". Dispone de una interfaz 
web que permite definir estos flujos. Por cuestiones de seguridad, se sugiere no permitir acceso directo desde clientes web 
a este entorno. En su lugar, se propone el uso de proxies que aíslen a [Apache NiFi](https://nifi.apache.org/) del exterior. 

![NIFI](https://nifi.apache.org/images/main-hero.svg)

En este repositorio desplegamos [Apache NiFi](https://nifi.apache.org/) detrás de [Traefik](https://doc.traefik.io/traefik/). [Traefik](https://doc.traefik.io/traefik/) es un proxy inverso y balanceador 
de carga de código abierto diseñado específicamente para microservicios y arquitecturas modernas basadas en contenedores, como Docker,
Kubernetes, y otras plataformas de orquestación. Su principal objetivo es simplificar el manejo de las rutas y el tráfico hacia
las aplicaciones distribuidas.

![Traefik](https://doc.traefik.io/traefik/assets/img/traefik-architecture.png)

Por su naturaleza, Nifi necesita de fuentes de información de las que extraer los datos que, posteriormente, serán procesadas y, quizás,
visualizadas mediante herramientas como Apache SuperSet. Como ejemplos de estas fuentes de datos, en este repositorio se 
despliegan mariadb y mongodb.

MariaDB is an open-source relational database management system (RDBMS) that is a fork of MySQL. It was created by the 
original developers of MySQL and is designed to remain free under the GNU General Public License. MariaDB is intended to 
be highly compatible with MySQL, ensuring that applications and tools that work with MySQL can also work with MariaDB with 
minimal or no changes. Para facilitar la administración de la base de datos, se despliega phpMyAdmin. phpMyAdmin is a 
free and open-source web-based administration tool for managing MySQL and MariaDB databases. It provides a graphical user
interface (GUI) to perform various database operations such as creating, modifying, and deleting databases, tables, fields, and rows.

MongoDB is an open-source, document-oriented NoSQL database designed for scalability, high performance, and ease of 
development. It stores data in flexible, JSON-like documents, which means fields can vary from document to document and data 
structure can be changed over time. Para facilitar la administración de la base de datos, se despliega mongo-express. 
MongoDB Express (mongo-express) is a web-based administrative interface for MongoDB. It provides a user-friendly GUI to interact with MongoDB databases, allowing users to perform various database operations such as viewing, querying, and modifying data

Para desplegar y orquestar este entorno, se hace uso de docker-compose. [Docker Compose](https://docs.docker.com/compose/) es una herramienta de Docker 
que permite definir y gestionar aplicaciones multicontenedor. Utiliza un archivo de configuración (generalmente llamado 
docker-compose.yml) para describir los servicios, redes y volúmenes necesarios para una aplicación y luego orquesta su 
despliegue con un solo comando.

# Instalación

Clone este repositorio ejecutando:

```bash
git clone https://github.com/ijfvianauhu/opendatalab-nifi.git
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
> Los contenidos albergados en `data` y `etc` tienen un carácter persistente, nunca se borrarán a no ser que lo haga de  
> forma explícita.

# Configuración

La configuración del despliegue se realiza mediante un fichero `.env`. Puede crearlo ejecutando la siguiente sentencia:
```bash
cp enviroment_variables.env docker/.env
```
En dicho fichero no encontraremos con las siguientes opciones:

* Variables comunes
* Variable traefik
* Variables nifi
* Variables mariadb
* Variables phpmyadmin
* Variables mongodb
* Variables mongo-express

## Variables comunes

El stack se configura globalmente estableciendo las siguientes variables

* **COMPOSE_PROJECT_NAME**: Nombre con el que se creará el stack. Por defecto, `nifi-opendatalab2`.
* **COMPOSE_USER**: Usuario que ejecutará el stack. Es recomendable poner el nombre del usuario del sistema que lanzará el comando docker (`id -u`). Por defecto, `1000`.
* **COMPOSE_GRP**: Grupo del usuario que ejecutará el stack. Es recomendable poner el nombre del usuario del sistema que lanzará el comando docker (`id -g`). Por defecto, `1000`.
* **COMPOSE_NETWORKNAME**. Nombre de la red que generará el stack. Por defecto, `nifi-opendatalab2-network`.

## Variables  Taefik

La configuración de traefik se puede ajustar mediante las siguientes variables:

* **TRAEFIK_IMAGE_NAME**. Nombre de la imagen de traefik a usar, por defecto vale `traefik`.
* **TRAEFIK_ACTIVE_BRANCH**. Versión de traefik a instalar, por defecto `v3.0`.
* **TRAEFIK_NAME**. Nombre del dominio que nos dará acceso al dashboard de traefik, por defecto vale `proxy.opendatalab2.uhu.es`.
* **TRAEFIK_HTTP_PORT**. Número de puerto usado para conexiones http. Por defecto, `80`.
* **TRAEFIK_HTTPS_PORT**. Número de puerto usado para conexiones https. Por defecto, `443`.
* **TRAEFIK_LOG_LEVEL**. Nivel de depuración de traefik. Por defecto, `DEBUG`.
* **TRAEFIK_ENABLE_DASHBOARD**. Se activa la web de monitorización de traefik. En caso de activarla hay que protegerla con usuario y clave. Por defecto, `true`
* **TRAEFIK_ADMIN_USER**. Nombre de usuario con acceso al dashboard de traefik. Por defecto, `admin`.
* **TRAEFIK_ADMIN_PASSWORD**. Clave de usuario con accedo al dashboard de traefik. Por defecto, `password`.

Para generar una clave para el usuario con acceso a traefik puede ejecutar el siguiente comando:
```bash
htpasswd -nb admin password 
```
El resultado de ejecutar este comando sería:
```
admin:$apr1$sctv3w4l$THkC377MZ8QS0J5.LU20m0
```
Los valores separados por un `:` son los deberemos asociar a las variables `TRAEFIK_ADMIN_USER` y `TRAEFIK_ADMIN_PASSWORD` respectivamente. 

Si no disponemos del comando htpasswd, podemos usar el servicio web [generator](https://hostingcanada.org/htpasswd-generator/)

## Variables  Nifi

Para configurar Nifi puedo establecer distintos valores para las siguientes variables:

* **NIFI_IMAGE_NAME**. Nombre de la imagen de nifi a usar. Por defecto, `apache/nifi`.
* **NIFI_ACTIVE_BRANCH**. Versión de nifi a instalar. ^pr defecto `"2.0.0"`.
* **NIFI_NAME**. Dominio que le asociaremos a la instancia de nifi creada. Por defecto, `nifi.opendatalab2.uhu.es`.
* **NIFI_WEB_HTTP_PORT**. Puerto para el protocolo http. Por defecto, `8080`.
* **NIFI_WEB_HTTPS_PORT**. Puerto para el protocolo https. Por defecto, `8443`.
* **NIFI_SINGLE_USER_CREDENTIALS_USERNAME**. Usuario para acceder al entorno nifi. Por defecto, `admin`.
* **NIFI_SINGLE_USER_CREDENTIALS_PASSWORD**. Clave del usuario que tiene acceso al entorno nifi. Por defecto, `ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB`.
* **NIFI_MOUNT_VOLUMES**. Indica si se montan los volúmenes. Por defecto, `true`.
* **NIFI_VOLUMES_DIR**. Directorio base desde donde se montaran los volúmenes.

## Variables mariadb

Para configurar mariadb puede establecer distintos valores para las siguientes variables:

* **MARIADB_IMAGE_NAME**: Nombre de la imagen mariadb a usar. Por defecto `mariadb`
* **MARIADB_ACTIVE_BRANCH**: Versión de mariadb a instalar. Por defecto, `10.5`
* **MARIADB_NAME**: Dominio que le asociaremos a la instancia de mariadb creada. Por defceto, `mariadb.opendatalab2.uhu.es`
* **MARIADB_PORT**: Puerto en el que escuchará la instancia de mariadb creada. Por defecto, `3306`
* **MARIADB_ROOT_PASSWORD**: Clave de root. Por defecto, `=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB`
* **MARIADB_VOLUMES_DIR**´: Localización del volumen en el que se almacenarán los datos de mariadb. Por defecto, `../data/mariadb`

## Variables phpmydmin

Para configurar phpmyadmin, puede establecer distintos valores para las siguientes variables:

* **PM_IMAGE_NAME**: Nombre de la imagen de phpmyadmin a usar. Por defecto. `phpmyadmin/phpmyadmin`
* **PM_ACTIVE_BRANCH**: Versión de phpmyadmin que se instalará. Por defecto, `5.1`
* **PM_NAME**: Dominio que le asociaremos a la instancia de mariadb creada. Por defecto, `phpmyadmin.opendatalab2.uhu.es`

## Variables mongodb

Para configurar mongodb, puede establecer distintos valores para las siguientes variables:

* **MONGO_IMAGE_NAME**: Nombre de la imagen de mongodb a instalar. Por defecto, `mongo`.
* **MONGO_ACTIVE_BRANCH**: Versión e mongodb a instalar. Por defecto, `4.4`.
* **MONGO_NAME**: Dominio que le asociaremos al contenedor de mongodb creado. Por defecto, `mongo.opendatalab2.uhu.es`.
* **MONGO_INITDB_ROOT_USERNAME**: Usuario administrador de mongodb. Por defecto, `root`.
* **MONGO_INITDB_ROOT_PASSWORD**: Contraseña del usuario administrador. Por defecto, `example`.
* **MONGO_VOLUMES_DIR**: Localización del volumen en el que se almacenarán los datos de mongodb. Por defecto,  `../data/mongo`.

## Variables mongo-express

Para configurar mongo-express, puede establecer distintos valores para las siguientes variables:

* **ME_IMAGE_NAME**: Nombre de la imagen de mongo-express que usaremos en el despliegue. Por defecto, `mongo-express`.
* **ME_ACTIVE_BRANCH**. Versión de mongo-express a instalar. Por defecto, `0.54`.
* **ME_NAME**. Dominio asociado al contenedor que albergará mongo-express. Por defecto, `mongo-express.opendatalab2.uhu.es`

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
NIFI_VOLUMES_DIR=../data/nifi

# mariadb
MARIADB_IMAGE_NAME=mariadb
MARIADB_ACTIVE_BRANCH="10.5"
MARIADB_NAME=mariadb.opendatalab2.uhu.es
MARIADB_PORT=3306
MARIADB_ROOT_PASSWORD=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB
MARIADB_VOLUMES_DIR=../data/mariadb

# phpmyadmin
PM_IMAGE_NAME=phpmyadmin/phpmyadmin
PM_ACTIVE_BRANCH="5.1"
PM_NAME=phpmyadmin.opendatalab2.uhu.es

# mongo
MONGO_IMAGE_NAME=mongo
MONGO_ACTIVE_BRANCH="4.4"
MONGO_NAME=mongo.opendatalab2.uhu.es
MONGO_INITDB_ROOT_USERNAME=root   # Usuario administrador para MongoDB
MONGO_INITDB_ROOT_PASSWORD=example # Contraseña del usuario administrador
MONGO_VOLUMES_DIR=../data/mongo

# mongo-express
ME_IMAGE_NAME=mongo-express
ME_ACTIVE_BRANCH="0.54"
ME_NAME=mongo-express.opendatalab2.uhu.es
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

Si, por algún motivo, deseamos acceder a los contenedores en ejecución. Lo podemos hacer ejecutando:

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



