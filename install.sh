#!/bin/bash

#  install.sh / uninstall.sh - Install or uninstall software

prefixDir="$HOME/opt"
# UserInstall activated? 0 => no, 1 => yes
UserInstall=1

#  if a (prefix) directory is provided, switch to system install
if [[ "$1" != "" ]]; then
	prefixDir="$1"
	UserInstall=0
fi

#  installation
if [[ "$(basename $0)" == "install.sh" ]]; then

	#  first create bin dir in home, if not already existing
	if [[ $UserInstall -eq 1 ]]; then	
		if [[ ! -e "$HOME/bin" ]]; then
			mkdir -p "$HOME/bin" &>/dev/null
		fi
	fi

	#  create directory structure
	mkdir -p "$prefixDir/gtransfer/bin" &>/dev/null
	mkdir -p "$prefixDir/gtransfer/share/doc" &>/dev/null
	mkdir -p "$prefixDir/gtransfer/share/man/man1" &>/dev/null

	#  create directory for configuration files and also copy configuration
	#+ files
	if [[ $UserInstall -eq 1 ]]; then
		mkdir -p "$HOME/.gtransfer" &>/dev/null
		cp ./etc/gtransfer/gtransfer.conf "$HOME/.gtransfer"
		cp ./etc/gtransfer/dpath.conf "$HOME/.gtransfer"
		cp ./etc/gtransfer/dparam.conf "$HOME/.gtransfer"
	else	
		mkdir -p "$prefixDir/gtransfer/etc" &>/dev/null
		cp ./etc/gtransfer/gtransfer.conf "$prefixDir/gtransfer/etc"
		cp ./etc/gtransfer/dpath.conf "$prefixDir/gtransfer/etc"
		cp ./etc/gtransfer/dparam.conf "$prefixDir/gtransfer/etc"
	fi

	#  copy scripts and...
	cp ./gtransfer.sh "$prefixDir/gtransfer/bin"
	cp ./datapath.sh "$prefixDir/gtransfer/bin"
	cp ./defaultparam.sh "$prefixDir/gtransfer/bin"

    #  reconfigure paths inside of the scripts
    #        + reconfigure path to configuration files
    #        |
    #        |                                                 + remove (special) comments
    #        |                                                 |
    sed -e "s|<PATH_TO_GTRANSFER>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$prefixDir/gtransfer/bin/gtransfer.sh"
    sed -e "s|<PATH_TO_GTRANSFER>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$prefixDir/gtransfer/bin/datapath.sh"
    sed -e "s|<PATH_TO_GTRANSFER>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$prefixDir/gtransfer/bin/defaultparam.sh"

	#  ...make links...
	if [[ $UserInstall -eq 1 ]]; then
		linkPath="$HOME"
	else
		linkPath="$prefixDir/gtransfer"
	fi
	ln -s "$prefixDir/gtransfer/bin/gtransfer.sh" "$linkPath/bin/gtransfer"	
	ln -s "$prefixDir/gtransfer/bin/gtransfer.sh" "$linkPath/bin/gt"
	ln -s "$prefixDir/gtransfer/bin/datapath.sh" "$linkPath/bin/dpath"
	ln -s "$prefixDir/gtransfer/bin/defaultparam.sh" "$linkPath/bin/dparam"

	#  copy README and manpages
	cp ./README "$prefixDir/gtransfer/share/doc"
	cp ./gtransfer.1.pdf ./dpath.1.pdf ./dparam.1.pdf "$prefixDir/gtransfer/share/doc"
	cp ./COPYING "$prefixDir/gtransfer/share/doc"

	cp ./gtransfer.1 "$prefixDir/gtransfer/share/man/man1"
	cp ./gt.1 "$prefixDir/gtransfer/share/man/man1"
	cp ./dpath.1 "$prefixDir/gtransfer/share/man/man1"
	cp ./dparam.1 "$prefixDir/gtransfer/share/man/man1"


#  uninstallation
elif [[ "$(basename $0)" == "uninstall.sh" ]]; then

	#  remove a system installed gtransfer
	if [[ "$1" != "" ]]; then
		rm -r "$prefixDir/gtransfer"
	#  remove a user installed gtransfer
	else
		#  remove scripts and links "$HOME/bin"
		rm "$HOME/bin/gtransfer"
		rm "$HOME/bin/gt"
		rm "$HOME/bin/dpath"
		rm "$HOME/bin/dparam"

		#  remove gtransfer dir
		rm -r "$prefixDir/gtransfer"

		#  remove basedir for dpaths, dparams and configuration files
		rm -r "$HOME/.gtransfer"
	fi
fi

