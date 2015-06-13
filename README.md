SowerPKG
========

SowerPKG corresponde a una herramienta que permite realizar la instalación y actualización del framework SowerPHP y sus extensiones oficiales.

Opciones
--------

Por defecto SowerPKG utiliza las siguientes opciones:

	EXTENSIONS=""
	FRAMEWORK_DIR="/usr/share/sowerphp"
	WWW_DIR="/var/www"
	COMPOSER="$HOME/bin/composer"

Donde *$HOME* será el directorio principal del usuario con que se ejecuta SowerPKG.

Esta herramienta almacena la configuración del framework en *~/.sowerpkg.conf*, esto con el fin de no tener que ingresar las opciones personalizadas cada vez.

Ejemplos de modo de uso
-----------------------

Instalar con opciones por defecto:

	$ ./sowerpkg.sh install

Instalar framework con extensión empresa y otras requeridas en directorio por defecto más nuevo proyecto en directorio personalizado dentro del *HOME* del usuario:

	$ ./sowerpkg.sh install -e "empresa app general" -w /home/delaf/public_html/webapp

Instalar el framework en directorio personalizado y sin directorio para proyecto web separado del framework:

	$ ./sowerpkg.sh install -d /home/delaf/public_html/sowerphp -W

Consultar ayuda de SowerPKG:

	$ ./sowerpkg.sh --help

**Importante**: siempre utilizar rutas absolutas en los parámetros.

La herramienta solicitará permisos de administrador (con *sudo*) de forma automática si son necesarios. Si el usuario realiza la instalación en directorios donde tiene permisos de escritura el uso de *sudo* no será necesario.

Requerimientos
--------------

Para realizar la instalación del framework y su posterior uso se requiere como mínimo:

- Servidor web Apache 2.x con mod\_rewrite activo y *AllowOverride All* para el o los directorios que alojarán los proyectos.
- PHP 5.5 o superior
- Git y mercurial

