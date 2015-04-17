#!/bin/bash

# gtransfer-version - returns version information for gtransfer toolkit and
# tools

:<<COPYRIGHT

Copyright (C) 2014 Frank Scheiner, HLRS, Universitaet Stuttgart

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

readonly _program=$( basename "$0" )
readonly _gtransferToolkitVersion="0.3.0RC1"

readonly _gtransferTools=( "gtransfer"
			   "dpath"
			   "dparam"
			   "halias" )

readonly _gtv_exit_usage=64
readonly _gtv_exit_ok=0

readonly _true=1
readonly _false=0

################################################################################
# FUNCTIONS
################################################################################

gtv/usageMsg()
{

	cat >&2 <<-USAGE
	Usage: $_program [-a]
	Try \`$_program --help' for more information.
	USAGE

	return
}


gtv/helpMsg()
{
    
	cat <<-HELP
	SYNOPSIS:

	$_program [options]

	DESCRIPTION:

	gt[ransfer]-version returns the version number of the gtransfer toolkit
	and the included tools

	OPTIONS:

	[-a, --all]		Print out the version numbers of all included
	                        tools.

	[--help]		Display this help and exit.
	
	Without arguments gtransfer-version prints the version number of the
	gtransfer toolkit.
	HELP

	return
}


gtv/printToolkitVersion()
{
	echo "gtransfer toolkit v$_gtransferToolkitVersion"
	
	return
}


gtv/printAllVersions()
{
	local _tool=""
	
	for _tool in "${_gtransferTools[@]}"; do

		$_tool --version
	done
	
	return
}
################################################################################
# MAIN
################################################################################

_mode="print-toolkit-version"

# read in all parameters
while [[ "$1" != "" ]]; do

	# only valid params used?
	#
	# NOTICE:
	# This was added to prevent high speed loops if parameters are
	# mispositioned.
	if [[   "$1" != "--help" && \
                "$1" != "--all" && "$1" != "-a" \
        ]]; then
		# no, so output a usage message
		gtv/usageMsg
		exit $_gtv_exit_usage
	fi
	
	# "--help"
	if [[ "$1" == "--help" ]]; then

		gtv/helpMsg
		exit $_gtv_exit_ok

	# "--all|-a"
	elif [[ "$1" == "--all" || "$1" == "-a" ]]; then

		_mode="print-all-versions"
		shift 1
	fi
done

if [[ "$_mode" == "print-toolkit-version" ]]; then

	gtv/printToolkitVersion

elif [[ "$_mode" == "print-all-versions" ]]; then

	gtv/printAllVersions
else
	gtv/usageMsg
	exit $_gtv_exit_usage
fi

exit

