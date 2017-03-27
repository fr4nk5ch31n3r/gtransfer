#!/bin/bash

# gtools.bash - GridFTP tools multicall executable

:<<COPYRIGHT

Copyright (C) 2016-2017 Frank Scheiner, HLRS, Universitaet Stuttgart

The program is distributed under the terms of the GNU General Public License
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

COPYRIGHT


################################################################################
# DEFINES
################################################################################

readonly _gtools_exit_usage=64
readonly _gtools_version="0.3.0"
readonly _program=$( basename $0 )


################################################################################
# PATH CONFIGURATION
################################################################################

# path to configuration files (prefer git deploy!)
# For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then

	gtransferConfigurationFilesPath="/etc/gtransfer"
	# gtransfer is installed in "/usr/bin", hence the base path is "/usr"
	gtransferBasePath="/usr"
	gtransferLibPath="$gtransferBasePath/share"
	gtransferLibexecPath="$gtransferBasePath/libexec/gtransfer"

# For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#
#sed#	gtransferConfigurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	gtransferBasePath=<GTRANSFER_BASE_PATH>
#sed#	gtransferLibPath="$gtransferBasePath/lib"
#sed#	gtransferLibexecPath="$gtransferBasePath/libexec"

# According to FHS 2.3, configuration files for packages located in "/opt" have
# to be placed here (if you use a provider super dir below "/opt" for the
# gtransfer files, please also use the same provider super dir below
# "/etc/opt").
#elif [[ -e "/etc/opt/<PROVIDER>/gtransfer" ]]; then
#
#	gtransferConfigurationFilesPath="/etc/opt/<PROVIDER>/gtransfer"
#	gtransferBasePath="/opt/<PROVIDER>/gtransfer"
#	gtransferLibPath="$gtransferBasePath/lib"
elif [[ -e "/etc/opt/gtransfer" ]]; then

	gtransferConfigurationFilesPath="/etc/opt/gtransfer"
	gtransferBasePath="/opt/gtransfer"
	gtransferLibPath="$gtransferBasePath/lib"
	gtransferLibexecPath="$gtransferBasePath/libexec"

# For user install in $HOME:
elif [[ -e "$HOME/opt/gtransfer" ]]; then

	gtransferConfigurationFilesPath="$HOME/.gtransfer"
	gtransferBasePath="$HOME/opt/gtransfer"
	gtransferLibPath="$gtransferBasePath/lib"
	gtransferLibexecPath="$gtransferBasePath/libexec"

# For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then

	gtransferConfigurationFilesPath="$( dirname $BASH_SOURCE )/../etc/gtransfer"
	gtransferBasePath="$( dirname $BASH_SOURCE )/../"
	gtransferLibPath="$gtransferBasePath/lib"
	gtransferLibexecPath="$gtransferBasePath/libexec"
fi

gtransferConfigurationFile="$gtransferConfigurationFilesPath/gtransfer.conf"

# Set $_LIB so gtransfer and its libraries can find their includes
readonly _LIB="$gtransferLibPath"

readonly _gtransfer_libraryPrefix="gtransfer"
readonly _GTRANSFER_LIBPATH="$_LIB/gtransfer"

# On SLES these files are located in `$_LIB/gtransfer`
if [[ -e "$_GTRANSFER_LIBPATH/getPidForUrl.r" && \
      -e "$_GTRANSFER_LIBPATH/getUrlForPid.r" && \
      -e "$_GTRANSFER_LIBPATH/packBinsNew.py" ]]; then

	readonly _GTRANSFER_LIBEXECPATH="$_GTRANSFER_LIBPATH"
else
	readonly _GTRANSFER_LIBEXECPATH="$gtransferLibexecPath"
fi


################################################################################
# INCLUDES
################################################################################

_neededLibraries=( "gtransfer/gridftp.bashlib" )

for _library in ${_neededLibraries[@]}; do

	if ! . "$_LIB/$_library" 2>/dev/null; then
		echo "$_program: Library \"$_LIB/$_library\" couldn't be read or is corrupted." 1>&2
		exit 70
	fi
done


################################################################################
# FUNCTIONS
################################################################################

gtools/gcat()
{
	local _url="$1"

	gridftp/cat "$_url"

	return
}


gtools/gcatHelpMsg()
{
	cat <<-HELP
		Usage: gcat <GRIDFTP_FILE_URL>
	HELP

	return
}


gtools/gmv()
{
	local _oldUrl="$1"
	local _newUrl="$2"

	gridftp/rename "$_oldUrl" "$_newUrl"

	return
}


gtools/gmvHelpMsg()
{
	cat <<-HELP
		Usage: gmv <OLD_GRIDFTP_URL> <NEW_GRIDFTP_URL>

		Only works when both <OLD_GRIDFTP_URL> and <NEW_GRIDFTP_URL> point to the same remote GridFTP service!
	HELP

	return
}


gtools/grm()
{
	local _url="$1"

	gridftp/removeFile "$_url"

	return
}


gtools/grmHelpMsg()
{
	cat <<-HELP
		Usage: grm <GRIDFTP_FILE_URL>

		Also works for empty directories!
	HELP

	return
}


gtools/gmkdir()
{
	local _url="$1"

	gridftp/mkdir "$_url"

	return
}


gtools/gmkdirHelpMsg()
{
	cat <<-HELP
		Usage: gmkdir <GRIDFTP_URL>

		Behaves like `mkdir -p [...]'!
	HELP

	return
}

gtools/gls()
{
	local _url="$1"

	gridftp/ls "$_url"

	return
}


gtools/glsHelpMsg()
{
	cat <<-HELP
		Usage: gls <GRIDFTP_URL>
	HELP

	return
}


gtools/versionMsg()
{
	echo "gtools v${_gtools_version} (gridftp.bashlib v${_gridftp_Version})"

	return
}


gtools/usageMsg()
{
	cat <<-USAGE
		Usage: gtools [function [arguments]...]
		   or: function [arguments]...

		       gtools is a multi-call shell script that combines various GridFTP
		       functionality into a single executable. Most people will create a
		       link to gtools for each function they wish to use and gtools will
		       act like whatever is was invoked as.

		Currently defined functions:
		       (g)cat, (g)ls, (g)mkdir, (g)mv, (g)rm
	USAGE

	return
}


################################################################################
# MAIN
################################################################################

# Short hands
case $( basename "$0" ) in

"gcat")
	exec gtools cat "$@"
	;;

"gls")
	exec gtools ls "$@"
	;;

"gmkdir")
	exec gtools mkdir "$@"
	;;

"gmv")
	exec gtools mv "$@"
	;;

"grm")
	exec gtools rm "$@"
	;;

*)
	:
	;;
esac

# correct number of params?
if [[ "$#" -lt "1" ]]; then
   # no, so output a usage message
   gtools/usageMsg
   exit $_gtools_exit_usage
fi

# read in all parameters
while [[ "$1" != "" ]]; do

	# only valid params used?
	if [[ "$1" != "cat" && \
	      "$1" != "ls" && \
	      "$1" != "mkdir" && \
	      "$1" != "mv" && \
	      "$1" != "rm" && \
	      "$1" != "--help" && "$1" != "-h" && \
	      "$1" != "--version" && "$1" != "-V" \
	]]; then
		# no, so output a usage message
		gtools/usageMsg
		exit $_gtools_exit_usage
	fi

	if [[ "$1" == "cat" ]]; then

		shift 1

		if [[ "$1" == "" ]]; then

			gtools/gcatHelpMsg
			exit $_gtools_exit_usage

		elif [[ "$1" == "--help" || \
		        "$1" == "-h" ]]; then

			gtools/gcatHelpMsg

		elif [[ "$1" == "--version" || \
		        "$1" == "-V" ]]; then

			gtools/versionMsg
		else
			gtools/gcat "$1"
		fi

		exit

	elif [[ "$1" == "ls" ]]; then

		shift 1

		if [[ "$1" == "" ]]; then

			gtools/glsHelpMsg
			exit $_gtools_exit_usage

		elif [[ "$1" == "--help" || \
		        "$1" == "-h" ]]; then

			gtools/glsHelpMsg

		elif [[ "$1" == "--version" || \
		        "$1" == "-V" ]]; then

			gtools/versionMsg
		else
			gtools/gls "$1"
		fi

		exit

	elif [[ "$1" == "mkdir" ]]; then

		shift 1

		if [[ "$1" == "" ]]; then

			gtools/gmkdirHelpMsg
			exit $_gtools_exit_usage

		elif [[ "$1" == "--help" || \
		        "$1" == "-h" ]]; then

			gtools/gmkdirHelpMsg

		elif [[ "$1" == "--version" || \
		        "$1" == "-V" ]]; then

			gtools/versionMsg
		else
			gtools/gmkdir "$1"
		fi

		exit

	elif [[ "$1" == "rm" ]]; then

		shift 1

		if [[ "$1" == "" ]]; then

			gtools/grmHelpMsg
			exit $_gtools_exit_usage

		elif [[ "$1" == "--help" || \
		        "$1" == "-h" ]]; then

			gtools/grmHelpMsg

		elif [[ "$1" == "--version" || \
		        "$1" == "-V" ]]; then

			gtools/versionMsg
		else
			gtools/grm "$1"
		fi

		exit

	elif [[ "$1" == "mv" ]]; then

		shift 1

		if [[ "$1" == "" ]]; then

			gtools/gmvHelpMsg
			exit $_gtools_exit_usage

		elif [[ "$1" == "--help" || \
		        "$1" == "-h" ]]; then

			gtools/gmvHelpMsg

		elif [[ "$1" == "--version" || \
		        "$1" == "-V" ]]; then

			gtools/versionMsg
		else
			if [[ "$2" == "" ]]; then

				echo "$_program: <NEW_GRIDFTP_URL> missing."
				gtools/gmvHelpMsg
				exit $_gtools_exit_usage
			else
				gtools/gmv "$1" "$2"
			fi
		fi

		exit

	elif [[ "$1" == "--help" || "$1" == "-h" ]]; then

		shift 1

		gtools/usageMsg

		exit

	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then

		shift 1

		gtools/versionMsg

		exit
	fi
done

exit
