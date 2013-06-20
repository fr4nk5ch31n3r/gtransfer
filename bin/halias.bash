# halias - (gtransfer) host aliases cli interface

:<<COPYRIGHT

Copyright (C) 2013 Frank Scheiner, HLRS, Universitaet Stuttgart

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
#  VARIABLES
################################################################################
readonly _true=1
readonly _false=0

readonly __GLOBAL__programName=$( basename "$0" )

readonly __GLOBAL__version="0.1.0"

version="$__GLOBAL__version"

#  path to configuration files (prefer system paths!)
#  For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then
        configurationFilesPath="/etc/gtransfer"
        #  gtransfer is installed in "/usr/bin", hence the base path is "/usr"
        basePath="/usr"
        libPath="$basePath/lib/gtransfer"

#  For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#	configurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	basePath=<GTRANSFER_BASE_PATH>
#sed#	libPath="$gtransferBasePath/lib"

#  According to FHS 2.3, configuration files for packages located in "/opt" have
#+ to be placed here (if you use a provider super dir below "/opt" for the
#+ gtransfer files, please also use the same provider super dir below
#+ "/etc/opt").
elif [[ -e "/etc/opt/gtransfer" ]]; then
        configurationFilesPath="/etc/opt/gtransfer"
        basePath="/opt/gtransfer"
        libPath="$basePath/lib"
#elif [[ -e "/etc/opt/<PROVIDER>/gtransfer" ]]; then
#	configurationFilesPath="/etc/opt/<PROVIDER>/gtransfer"
#	basePath="/opt/<PROVIDER>/gtransfer"
#	libPath="$gtransferBasePath/lib"

#  For user install in $HOME:
elif [[ -e "$HOME/.gtransfer" ]]; then
        configurationFilesPath="$HOME/.gtransfer"
        basePath="$HOME/opt/gtransfer"
        libPath="$basePath/lib"

#  For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then
	configurationFilesPath="$( dirname $BASH_SOURCE )/../etc"
	basePath="$( dirname $BASH_SOURCE )/../"
	libPath="$basePath/lib"
fi

configurationFile="$configurationFilesPath/aliases.conf"

#  Set $_LIB so halias and its libraries can find their includes
readonly _LIB="$libPath"

################################################################################
#  INCLUDE LIBRARY FUNCTIONS
################################################################################

. "$_LIB"/exitCodes.bashlib
. "$_LIB"/alias.bashlib

################################################################################


################################################################################
#  FUNCTIONS
################################################################################
usageMsg()
{
        cat <<USAGE

usage:	$__GLOBAL__programName [--help]
	$__GLOBAL__programName --list
	$__GLOBAL__programName --dealias alias
	$__GLOBAL__programName --is-alias alias

--help gives more information

USAGE
        return
}


helpMsg()
{
        cat <<HELP

$(versionMsg)

SYNOPSIS:

$__GLOBAL__programName [OPTION] STRING

DESCRIPTION:

halias (host alias) is a small helper utility providing an interface to the
alias bashlib. It can be used to list or expand host aliases and also to check
if a given string is an alias.

OPTIONS:

The options are as follows:

-l, --list		List all available host aliases.
			
-d, --dealias STRING	Expand a given string. If STRING is not a host alias,
			then STRING is just printed.
			
-i, --is-alias STRING	Check if a given string is a host alias. Returns 0 if
			yes, 1 otherwise.

    --help		Display this help and exit.

-V, --version		Output version information and exit.

HELP

	return
}


versionMsg()
{
	cat <<-VERSION
$__GLOBAL__programName v${__GLOBAL__version}
	VERSION
	
	return
}


halias/list()
{
	local _userAliases=""
	local _systemAliases=""

	if [[ -e "$__GLOBAL__userAliasesSource" ]]; then
		_userAliases=$( alias/list "$__GLOBAL__userAliasesSource" )
	fi
	if [[ -e "$__GLOBAL__systemAliasesSource" ]]; then
		_systemAliases=$( alias/list "$__GLOBAL__systemAliasesSource" )
	fi

	if [[ ! -z "$_userAliases" && ! -z "$_systemAliases" ]]; then
	
		echo -e "$_userAliases\n$_systemAliases" | sort -u
		
	elif [[ ! -z "$_userAliases" ]]; then
	
		echo "$_userAliases"
		
	elif  [[ ! -z "$_systemAliases" ]]; then
	
		echo "$_systemAliases"
	fi
	
	return		
}


halias/isAlias()
{
	local _string="$1"
	
	# The library function checks for existence of aliases source, so not
	# needed here.
	#if [[ -e "$__GLOBAL__userAliasesSource" ]]; then
		if alias/isAlias "$_string" "$__GLOBAL__userAliasesSource"; then
			return 0
		fi
	#fi
	
	#if [[ -e "$__GLOBAL__systemAliasesSource" ]]; then
		if alias/isAlias "$_string" "$__GLOBAL__systemAliasesSource"; then
			return 0
		fi
	#fi
	
	return 1
}


halias/dealias()
{
	local _string="$1"
	
	local _dealiasedString=""
	
	_dealiasedString=$( alias/dealias "$_string" "$__GLOBAL__userAliasesSource" )
	
	# If _string is a user alias, _dealiasedString will differ from it and
	# we can return, as user aliases take precedence.
	if [[ "$_dealiasedString" != "$_string" ]]; then
		echo "$_dealiasedString"
		return 0
	fi
	
	_dealiasedString=$( alias/dealias "$_string" "$__GLOBAL__systemAliasesSource" )
	
	# If _string is a system alias, _dealiasedString will differ from it...
	if [[ "$_dealiasedString" != "$_string" ]]; then
		echo "$_dealiasedString"
		return 0
	fi
	
	# ...if not, we just return the input string
	echo "$_string"
	
	return
}

################################################################################

################################################################################
#  MAIN
################################################################################

#  load configuration file
if [[ -e "$configurationFile" ]]; then
	. "$configurationFile"
	# The following global vars are defined there:
	# __GLOBAL__userAliasesSource
	# __GLOBAL__systemAliasesSource
else
	echo "$__GLOBAL__programName: configuration file missing!"
	exit $_gtransfer_exit_software
fi

#  correct number of params?
if [[ "$#" -lt "1" ]]; then
   # no, so output a usage message
   usageMsg
   exit $_gtransfer_exit_usage
fi

# read in all parameters
while [[ "$1" != "" ]]; do

	#  only valid params used?
	if [[   "$1" != "--help" && \
		"$1" != "--version" && "$1" != "-V" && \
		"$1" != "--list" && "$1" != "-l" && \
		"$1" != "--dealias" && "$1" != "-d" && \
		"$1" != "--is-alias" && "$1" != "-i" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit $_gtransfer_exit_usage
	fi

	#  "--help"
	if [[ "$1" == "--help" ]]; then
		helpMsg
		exit $_gtransfer_exit_ok

	#  "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then
		versionMsg
		exit $_gtransfer_exit_ok

	#  "--list|-l"
	elif [[ "$1" == "--list" || "$1" == "-l" ]]; then
		halias/list
		exit
	
	# "--is-alias|-i"
	elif [[ "$1" == "--is-alias" || "$1" == "-i" ]]; then
		shift 1
		halias/isAlias "$1"
		exit
	
	# "--dealias|-d"
	elif [[ "$1" == "--dealias" || "$1" == "-d" ]]; then
		shift 1
		halias/dealias "$1"
		exit
	fi
done

