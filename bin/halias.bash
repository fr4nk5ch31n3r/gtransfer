#!/bin/bash
# halias - (gtransfer) host aliases cli interface

:<<COPYRIGHT

Copyright (C) 2013, 2017 Frank Scheiner, HLRS, Universitaet Stuttgart

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
# VARIABLES
################################################################################
readonly _true=1
readonly _false=0

readonly __GLOBAL__programName=$( basename "$0" )

readonly __GLOBAL__version="0.3.0"

# path to configuration files (prefer system paths!)
# For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then

	configurationFilesPath="/etc/gtransfer"
	# gtransfer is installed in "/usr/bin", hence the base path is "/usr"
	basePath="/usr"
	libPath="$basePath/share"

# For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#
#sed#	configurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	basePath=<GTRANSFER_BASE_PATH>
#sed#	libPath="$basePath/lib"

# According to FHS 2.3, configuration files for packages located in "/opt" have
# to be placed here (if you use a provider super dir below "/opt" for the
# gtransfer files, please also use the same provider super dir below
# "/etc/opt").
elif [[ -e "/etc/opt/gtransfer" ]]; then

	configurationFilesPath="/etc/opt/gtransfer"
	basePath="/opt/gtransfer"
	libPath="$basePath/lib"

#elif [[ -e "/etc/opt/<PROVIDER>/gtransfer" ]]; then
#
#	configurationFilesPath="/etc/opt/<PROVIDER>/gtransfer"
#	basePath="/opt/<PROVIDER>/gtransfer"
#	libPath="$gtransferBasePath/lib"

# For user install in $HOME:
elif [[ -e "$HOME/opt/gtransfer" ]]; then

	configurationFilesPath="$HOME/.gtransfer"
	basePath="$HOME/opt/gtransfer"
	libPath="$basePath/lib"

# For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then

	configurationFilesPath="$( dirname $BASH_SOURCE )/../etc/gtransfer"
	basePath="$( dirname $BASH_SOURCE )/../"
	libPath="$basePath/lib"
fi

configurationFile="$configurationFilesPath/aliases.conf"

# Set $_LIB so halias and its libraries can find their includes
readonly _LIB="$libPath"
readonly _gtransfer_libraryPrefix="gtransfer"


################################################################################
# INCLUDE LIBRARY FUNCTIONS
################################################################################

. "$_LIB"/${_gtransfer_libraryPrefix}/exitCodes.bashlib
. "$_LIB"/${_gtransfer_libraryPrefix}/alias.bashlib

################################################################################


################################################################################
# FUNCTIONS
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
if a given string is an alias. In addition it can also be used to retrieve and
install host aliases from a pre-configured repository.

OPTIONS:

The options are as follows:

-l, --list		List all available host aliases.

-d, --dealias STRING	Expand a given string. If STRING is not a host alias,
			then STRING is just printed.

-i, --is-alias STRING	Check if a given string is a host alias. Returns 0 if
			yes, 1 otherwise.

-r, --retrieve [/path/to/host-aliases] [-q]
			Retrieve host aliases available on a repository at:

			<$__CONFIG__hostAliasesUrl>

			...and store them in the user-provided path or - if no
			additional path is given - in the user host aliases
			directory. If a "-q" is provided, then output is omitted
			and success/failure is only reported by the exit value.

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


# Public: List available host aliases.
#
# Returns 0 on success, 1 otherwise.
halias/list()
{
	local _userAliases=""
	local _systemAliases=""

	if [[ -e "$__CONFIG__userAliasesSource" ]]; then

		_userAliases=$( alias/list "$__CONFIG__userAliasesSource" )
	fi

	if [[ -e "$__CONFIG__systemAliasesSource" ]]; then

		_systemAliases=$( alias/list "$__CONFIG__systemAliasesSource" )
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


# Public: Check if given string is a host alias.
#
# $1 (_string) - Alias string to check
#
# Returns 0 on success (i.e. given string is an alias), 1 otherwise.
halias/isAlias()
{
	local _string="$1"

	if alias/isAlias "$_string" "$__CONFIG__userAliasesSource"; then
		return 0
	fi

	if alias/isAlias "$_string" "$__CONFIG__systemAliasesSource"; then
		return 0
	fi

	return 1
}


# Public: Resolve/dealiase the given string. If the given input string is not a
#         host alias, it is just printed. If it is a host alias the dealiased
#         value is printed.
#
# $1 (_string) - String to resolve/dealias.
#
# Returns 0 on success, 1 otherwise.
halias/dealias()
{
	local _string="$1"

	local _dealiasedString=""

	_dealiasedString=$( alias/dealias "$_string" "$__CONFIG__userAliasesSource" )

	# If _string is a user alias, _dealiasedString will differ from it and
	# we can return, as user aliases take precedence.
	if [[ $? -ne 1 && "$_dealiasedString" != "$_string" ]]; then

		echo "$_dealiasedString"
		return 0
	fi

	_dealiasedString=$( alias/dealias "$_string" "$__CONFIG__systemAliasesSource" )

	# If _string is a system alias, _dealiasedString will differ from it...
	if [[ $? -ne 1 && "$_dealiasedString" != "$_string" ]]; then

		echo "$_dealiasedString"
		return 0
	fi

	# ...if not, we just print the input string
	echo "$_string"

	return
}


# Public: Retrieve host aliases from configured (remote) repository.
#
# $1 (_quiet)                 - Quiet operation (true (=1)/false (=0))
# $2 (_hostAliasesDir)        - Where to store the host aliaes.
#
# __CONFIG__hostAliasesUrl    - The URL of the host aliases packgage.
# __CONFIG__hostAliasesUrlPkg - The file name of the host aliases package (has
#                               to be a gzipped tar archive)
#
# Returns 0 on success, 1 otherwise.
halias/retrieveHostAliases()
{
	local _quiet="$1"
	local _hostAliasesDir="$2"

	# default to quiet operation
	local _gucVerbose=""
	local _tarVerbose=""

	if [[ $_quiet -eq $_true ]]; then

		: # use defaults
	else
		# make guc and tar verbose
		_gucVerbose="-v"
		_tarVerbose="-v"
	fi

	if [[ ! -e "$_hostAliasesDir" ]]; then

		mkdir -p "$_hostAliasesDir"
	fi

	# retrieve host aliases to host aliases dir
	export GLOBUS_FTP_CLIENT_SOURCE_PASV=1

	cd "$_hostAliasesDir"

	if ! globus-url-copy $_gucVerbose "$__CONFIG__hostAliasesUrl" "file://$PWD/"; then

		# when failing, guc leaves an empty file in $_hostAliasesDir!
		rm -f "$__CONFIG__hostAliasesUrlPkg"
		return 1
	fi

	if ! ( tar $_tarVerbose -xzf "$__CONFIG__hostAliasesUrlPkg" && \
	       rm "$__CONFIG__hostAliasesUrlPkg" ); then

		return 1
	fi

	return 0
}


################################################################################
# MAIN
################################################################################
# load configuration file
if [[ -e "$configurationFile" ]]; then

	. "$configurationFile"
	# The following configuration vars are defined there:
	# __CONFIG__userAliasesSource
	# __CONFIG__systemAliasesSource
	# __CONFIG__hostAliasesUrl
else
	echo "$__GLOBAL__programName: configuration file missing!"
	exit $_gtransfer_exit_software
fi

# correct number of params?
if [[ "$#" -lt "1" ]]; then

	# no, so output a usage message
	usageMsg
	exit $_gtransfer_exit_usage
fi

# read in all parameters
while [[ "$1" != "" ]]; do

	# only valid params used?
	if [[   "$1" != "--help" && \
		"$1" != "--version" && "$1" != "-V" && \
		"$1" != "--list" && "$1" != "-l" && \
		"$1" != "--dealias" && "$1" != "-d" && \
		"$1" != "--is-alias" && "$1" != "-i" && \
		"$1" != "--retrieve" && "$1" != "-r" \
	]]; then
		# no, so output a usage message
		usageMsg
		exit $_gtransfer_exit_usage
	fi

	# ""--help"
	if [[ "$1" == "--help" ]]; then

		helpMsg
		exit $_gtransfer_exit_ok

	# "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then

		versionMsg
		exit $_gtransfer_exit_ok

	# "--list|-l"
	elif [[ "$1" == "--list" || "$1" == "-l" ]]; then

		halias/list
		exit

	# "--is-alias|-i"
	elif [[ "$1" == "--is-alias" || "$1" == "-i" ]]; then

		_option="$1"
		shift 1

		if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then

			halias/isAlias "$1"
			exit
		else
			echo "$__GLOBAL__programName: Missing argument for option \"$_option\"!" 1>&2
			usageMsg
			exit $_gtransfer_exit_usage
		fi

	# "--dealias|-d"
	elif [[ "$1" == "--dealias" || "$1" == "-d" ]]; then

		_option="$1"
		shift 1

		if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then

			halias/dealias "$1"
			exit
		else
			echo "$__GLOBAL__programName: Missing argument for option \"$_option\"!" 1>&2
			usageMsg
			exit $_gtransfer_exit_usage
		fi

	# "-r, --retrieve"
	elif [[ "$1" == "--retrieve" || "$1" == "-r" ]]; then

		_option="$1"
		shift 1

		if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then

			_hostAliasesDir="$1"
			shift 1

			if [[ "$1" == "-q" ]]; then

				halias/retrieveHostAliases "$_true" "$_hostAliasesDir"
			else
				halias/retrieveHostAliases "$_false" "$_hostAliasesDir"
			fi

			exit

		elif [[ "$1" == "-q" ]]; then

			_hostAliasesDir="$__CONFIG__userAliasesSource"
			halias/retrieveHostAliases "$_true" "$_hostAliasesDir"

			exit
		else
			_hostAliasesDir="$__CONFIG__userAliasesSource"
			halias/retrieveHostAliases "$_false" "$_hostAliasesDir"

			exit
		fi
	fi
done
