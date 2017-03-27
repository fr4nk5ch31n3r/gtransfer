#!/bin/bash

# install.bash / uninstall.bash - Install or uninstall software

# if a (prefix) directory is provided, switch to system install
if [[ "$1" != "" ]]; then

	# user install activated? 0 => no, 1 => yes
	userInstall=0

	prefixDir="$1"
	etcDir="$prefixDir/gtransfer/etc"
else
	# user install activated? 0 => no, 1 => yes
	userInstall=1

	prefixDir="$HOME/opt"
	etcDir="$HOME/.gtransfer"
fi

binDir="$prefixDir/gtransfer/bin"
docDir="$prefixDir/gtransfer/share/doc"
manDir="$prefixDir/gtransfer/share/man"
libDir="$prefixDir/gtransfer/lib"
libexecDir="$prefixDir/gtransfer/libexec"

# installation
if [[ "$(basename $0)" == "install.bash" ]]; then

	# first create bin dir in home, if not already existing
	if [[ $userInstall -eq 1 ]]; then

		if [[ ! -e "$HOME/bin" ]]; then

			mkdir -p "$HOME/bin" &>/dev/null
		fi
	fi

	# create directory structure
	mkdir -p "$binDir" &>/dev/null
	mkdir -p "$docDir" &>/dev/null
	mkdir -p "$manDir/man1" &>/dev/null
	mkdir -p "$etcDir" &>/dev/null
	mkdir -p "$etcDir/dpaths" &>/dev/null
	mkdir -p "$etcDir/dparams" &>/dev/null
	mkdir -p "$libDir" &>/dev/null
	mkdir -p "$libexecDir" &>/dev/null

	# copy configuration files (also copy bash completion file)
	#cp ./etc/gtransfer/gtransfer.conf_example \
        #   ./etc/gtransfer/dpath.conf_example \
        #   ./etc/gtransfer/dparam.conf_example \
        #   ./etc/gtransfer/dpath.template_example \
        #   ./etc/gtransfer/chunkConfig_example \
        #   ./etc/gtransfer/aliases_example \
        #   ./etc/gtransfer/aliases.conf_example "$etcDir"
        cp -r --backup=numbered ./etc/gtransfer/* "$etcDir"
	cp -r ./etc/bash_completion.d "$etcDir"

	# copy scripts and...
	cp ./bin/gtransfer.bash \
	   ./bin/datapath.bash \
	   ./bin/defaultparam.bash \
	   ./bin/halias.bash \
	   ./bin/gtools.bash "$binDir"

	# ...reconfigure paths inside of the scripts and...
	#        + reconfigure path to configuration files
	#        |                                                 + remove (special) comments
	#        |                                                 |
	sed -e "s|<GTRANSFER_BASE_PATH>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$binDir/gtransfer.bash"
	sed -e "s|<GTRANSFER_BASE_PATH>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$binDir/datapath.bash"
	sed -e "s|<GTRANSFER_BASE_PATH>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$binDir/defaultparam.bash"
	sed -e "s|<GTRANSFER_BASE_PATH>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$binDir/halias.bash"
	sed -e "s|<GTRANSFER_BASE_PATH>|$prefixDir/gtransfer|g" -e 's/#sed#//g' -i "$binDir/gtools.bash"

	# ...make links and...
	if [[ $userInstall -eq 1 ]]; then

		linkPath="$HOME/bin"

		ln -s "$binDir/gtransfer.bash" "$linkPath/gtransfer"
		ln -s "$binDir/gtransfer.bash" "$linkPath/gt"
		ln -s "$binDir/datapath.bash" "$linkPath/dpath"
		ln -s "$binDir/defaultparam.bash" "$linkPath/dparam"
		ln -s "$binDir/halias.bash" "$linkPath/halias"
		ln -s "$binDir/gtransfer-version.bash" "$linkPath/gt-version"
		ln -s "$binDir/gtools.bash" "$linkPath/gtools"
		ln -s "$binDir/gtools.bash" "$linkPath/gcat"
		ln -s "$binDir/gtools.bash" "$linkPath/gls"
		ln -s "$binDir/gtools.bash" "$linkPath/gmkdir"
		ln -s "$binDir/gtools.bash" "$linkPath/gmv"
		ln -s "$binDir/gtools.bash" "$linkPath/grm"
	else
		linkPath="$binDir"

		# no path in links for system install!
		ln -s "gtransfer.bash" "$linkPath/gtransfer"
		ln -s "gtransfer.bash" "$linkPath/gt"
		ln -s "datapath.bash" "$linkPath/dpath"
		ln -s "defaultparam.bash" "$linkPath/dparam"
		ln -s "halias.bash" "$linkPath/halias"
		ln -s "gtransfer-version.bash" "$linkPath/gt-version"
		ln -s "gtools.bash" "$linkPath/gtools"
		ln -s "gtools.bash" "$linkPath/gcat"
		ln -s "gtools.bash" "$linkPath/gls"
		ln -s "gtools.bash" "$linkPath/gmkdir"
		ln -s "gtools.bash" "$linkPath/gmv"
		ln -s "gtools.bash" "$linkPath/grm"
	fi

	# ...copy README and manpages.
	#cp ./share/doc/README.md \
	#   ./share/doc/gtransfer.1.pdf \
	#   ./share/doc/dpath.1.pdf \
	#   ./share/doc/dparam.1.pdf \
	#   ./COPYING "$docDir"
	cp -r ./share/doc/* ./README.md ./COPYING "$docDir"

	# update paths in README.md
	sed -e 's|/share/doc/||g' -e 's|/COPYING|COPYING|' -i "$docDir/README.md"

	#cp ./share/man/man1/gtransfer.1 \
	#   ./share/man/man1/gt.1 \
	#   ./share/man/man1/dpath.1 \
	#   ./share/man/man1/dparam.1 "$manDir/man1"
	cp -r ./share/man/* "$manDir/"

	# copy libraries
	cp -r ./lib/* "$libDir"

	# copy helper tools
	cp -r ./libexec/* "$libexecDir"

#  uninstallation
elif [[ "$(basename $0)" == "uninstall.bash" ]]; then

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
		rm "$HOME/bin/halias"
		rm "$HOME/gt-version"
		rm "$HOME/bin/gtools"
		rm "$HOME/bin/gcat"
		rm "$HOME/bin/gls"
		rm "$HOME/bin/gmkdir"
		rm "$HOME/bin/gmv"
		rm "$HOME/bin/grm"

		#  remove gtransfer dir
		rm -r "$prefixDir/gtransfer"
	fi
fi
