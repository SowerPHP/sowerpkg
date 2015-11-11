#!/bin/bash
#
# SowerPKG
# Copyright (C) 2015 Esteban De La Fuente Rubio (esteban[at]delaf.cl)
#
# Este programa es software libre: usted puede redistribuirlo y/o modificarlo
# bajo los términos de la Licencia Pública General GNU publicada
# por la Fundación para el Software Libre, ya sea la versión 3
# de la Licencia, o (a su elección) cualquier versión posterior de la misma.
#
# Este programa se distribuye con la esperanza de que sea útil, pero
# SIN GARANTÍA ALGUNA; ni siquiera la garantía implícita
# MERCANTIL o de APTITUD PARA UN PROPÓSITO DETERMINADO.
# Consulte los detalles de la Licencia Pública General GNU para obtener
# una información más detallada.
#
# Debería haber recibido una copia de la Licencia Pública General GNU
# junto a este programa.
# En caso contrario, consulte <http://www.gnu.org/licenses/gpl.html>.
#

#
# Administrador de paquetes para SowerPHP, permite instalar y actualizar el
# framework
#

# configuración por defecto
EXTENSIONS=""
FRAMEWORK_DIR="/usr/share/sowerphp"
WWW_DIR="/var/www"
COMPOSER="$HOME/bin/composer"

# configuraciones que no dependen del usuario
CONFIG="$HOME/.sowerpkg.conf"
LOG="/tmp/sowerpkg_`whoami`_`date +%Y%m%d%H%M%S`.log"

# función que guarda las configuraciones en el archivo de configuración
function sowerphp_config {
	echo "EXTENSIONS=\"$EXTENSIONS\"" > $CONFIG
	echo "FRAMEWORK_DIR=\"$FRAMEWORK_DIR\"" >> $CONFIG
	echo "WWW_DIR=\"$WWW_DIR\"" >> $CONFIG
	echo "COMPOSER=\"$COMPOSER\"" >> $CONFIG
}

# función que muestra ayuda del comando
function sowerphp_help {
	echo -e "Administrador de paquetes de SowerPHP\n"
	echo -e "\tModo de uso: $0 ACCIÓN [OPCIONES]\n"
	echo -e "Acciones:"
	echo -e "\thelp\t\tMuestra esta ayuda"
	echo -e "\tinstall\t\tInstala SowerPHP"
	echo -e "\tupdate\t\tActualiza SowerPHP"
	echo -e "\nOpciones:"
	echo -e "\t-e \"...\"\tExtensiones oficiales del framework (separadas por espacio)"
	echo -e "\t\t\tValor actual: $EXTENSIONS"
	echo -e "\t-d DIR\t\tDirectorio base del framework"
	echo -e "\t\t\tValor actual: $FRAMEWORK_DIR"
	echo -e "\t-w DIR\t\tDirectorio de la aplicación web"
	echo -e "\t\t\tValor actual: $WWW_DIR"
	echo -e "\t-W\t\tNo instalar aplicación web (sólo el framework)"
	echo -e "\t-c COMPOSER\tUbicación de composer"
	echo -e "\t\t\tValor actual: $COMPOSER"
	echo -e "\nSi existe $CONFIG se utilizará para sobreescribir las opciones por defecto"
	echo -e ""
}

# función que muestra el modo de uso del comando
function sowerphp_usemode {
	echo "Modo de uso: $0 ACCIÓN [OPCIONES]"
	echo "Pruebe '$0 --help' para más información."
}

# función para verificar requerimientos para la instalación
function sowerphp_req {
	CMDS="php git hg"
	for CMD in $CMDS; do
		command -v $CMD >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Debe instalar $CMD antes de continuar!"
			exit 1
		fi
	done
	sowerphp_req_composer
}

# función para instalar composer si no existe
function sowerphp_req_composer {
	command -v $COMPOSER >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		COMPOSER_DIR=`dirname $COMPOSER`
		COMPOSER_FILE=`basename $COMPOSER`
		if [ ! -d "$COMPOSER_DIR" ]; then
			mkdir -p "$COMPOSER_DIR"
		fi
		curl -sS https://getcomposer.org/installer | php -- --install-dir=$COMPOSER_DIR --filename=$COMPOSER_FILE > /dev/null
	fi
}

# función para realizar la instalación del framework y creación de primer proyecto
function sowerphp_install {
	sowerphp_install_framework
	if [ ! -z "$WWW_DIR" ]; then
		sowerphp_create_project "$WWW_DIR"
	fi
	# mostrar mensaje log guardado
	echo "Log guardado en $LOG"
}

# función para realizar la instalación del framework
function sowerphp_install_framework {
	# instalar framework
	echo -n "Instalando SowerPHP... "
	if [ -d "$FRAMEWORK_DIR" ]; then
		rm -rf "$FRAMEWORK_DIR" 2> /dev/null
		if [ $? -ne 0 ]; then
			sudo rm -rf "$FRAMEWORK_DIR"
		fi
	fi
	mkdir -p "$FRAMEWORK_DIR" 2> /dev/null
	if [ $? -ne 0 ]; then
		sudo mkdir -p "$FRAMEWORK_DIR"
		sudo chown `whoami`: "$FRAMEWORK_DIR" -R
	fi
	git clone https://github.com/SowerPHP/sowerphp.git "$FRAMEWORK_DIR" >> $LOG 2>&1
	if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
	# instalar dependencias de composer
	cd "$FRAMEWORK_DIR/lib/sowerphp/core"
	echo -n " Instalando dependencias de composer... "
	$COMPOSER install >> $LOG 2>&1
	if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
	# instalar extensiones
	if [ ! -z "$EXTENSIONS" ]; then
		echo "Instalando extensiones:"
		EXTENSIONS_DIR="$FRAMEWORK_DIR/extensions/sowerphp"
		mkdir -p "$EXTENSIONS_DIR"
		for EXTENSION in $EXTENSIONS; do
			echo -n " - Instalando extensión ${EXTENSION}... "
			git clone https://github.com/SowerPHP/extension-${EXTENSION}.git "$EXTENSIONS_DIR/$EXTENSION" >> $LOG 2>&1
			if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
			# instalar dependencias de composer
			cd "$EXTENSIONS_DIR/$EXTENSION"
			echo -n "    Instalando dependencias de composer... "
			$COMPOSER install >> $LOG 2>&1
			if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
		done
	fi
}

# función para crear un proyecto
function sowerphp_create_project {
	echo -n "Creando proyecto web... "
	WWW_DIR=$1
	if [ -d "$WWW_DIR" ]; then
		echo "FAIL!"
		echo " Directorio $WWW_DIR ya existe!"
	else
		PARENT_DIR=`dirname "$WWW_DIR"`
		if [ ! -d "$PARENT_DIR" ]; then
			mkdir -p "$PARENT_DIR" 2> /dev/null
			if [ $? -ne 0 ]; then
				sudo mkdir -p "$PARENT_DIR"
				sudo chown `whoami`: "$PARENT_DIR" -R
			fi
		fi
		if [ -d "$FRAMEWORK_DIR/project" ]; then
			cp -a "$FRAMEWORK_DIR/project" "$WWW_DIR" 2> /dev/null
			if [ $? -ne 0 ]; then
				sudo cp -a "$FRAMEWORK_DIR/project" "$WWW_DIR" > /dev/null
				sudo chown `whoami`: "$WWW_DIR" -R
			fi
			sed -i 's/dirname(dirname(dirname(dirname(__FILE__))))/"'"${FRAMEWORK_DIR//\//\\/}"'"/' "$WWW_DIR/website/webroot/index.php"
			if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
		else
			echo "FAIL!"
			echo " Directorio $FRAMEWORK_DIR/project no existe!"
		fi
	fi
}

# función para realizar la actualización del framework
function sowerphp_update {
	# actualizar framework
	echo -n "Actualizando SowerPHP... "
	cd "$FRAMEWORK_DIR"
	git pull origin master >> $LOG 2>&1
	if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
	# actualizar dependencias de composer
	cd "$FRAMEWORK_DIR/lib/sowerphp/core"
	echo -n " Actualizando dependencias de composer... "
	$COMPOSER update >> $LOG 2>&1
	if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
	# actualizar extensiones
	if [ ! -z "$EXTENSIONS" ]; then
		EXTENSIONS_DIR="$FRAMEWORK_DIR/extensions/sowerphp"
		for EXTENSION in $EXTENSIONS; do
			echo -n " - Actualizando extensión ${EXTENSION}... "
			cd "$EXTENSIONS_DIR/$EXTENSION"
			git pull origin master >> $LOG 2>&1
			if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
			# actualizar dependencias de composer
			echo -n "    Actualizando dependencias de composer... "
			$COMPOSER update >> $LOG 2>&1
			if [ $? -eq 0 ]; then echo "OK!"; else echo "FAIL!"; fi
		done
	fi
	# mostrar mensaje log guardado
	echo "Log guardado en $LOG"
}

# si no se pasó ninguna acción se muestra mensaje modo de uso
if [ $# -eq 0 ]; then
	sowerphp_usemode
	exit 1
fi

# obtener acción
ACCION=$1
shift

# cargar archivo de configuración si existe
if [ -r "$CONFIG" ]; then
	. $CONFIG
fi

# parsear argumentos
while [[ $# > 0 ]]; do
	case $1 in
		-e) EXTENSIONS="$2"; shift;;
		-d) FRAMEWORK_DIR="$2"; shift;;
		-w) WWW_DIR="$2"; shift;;
		-W) WWW_DIR="";;
		-c) COMPOSER="$2"; shift;;
	esac
	shift
done

# guardar configuraciones en archivo de configuración
sowerphp_config

# verificar requerimientos para instalación
sowerphp_req

# ejecutar acción
case $ACCION in
	install) sowerphp_install;;
	update) sowerphp_update;;
	help|--help|-h) sowerphp_help;;
	*) sowerphp_usemode; exit 1;;
esac

