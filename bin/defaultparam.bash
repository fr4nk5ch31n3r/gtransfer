#!/bin/bash

# dparam - default params creation, listing, retrieving

:<<COPYRIGHT

Copyright (C) 2011, 2013, 2017 Frank Scheiner, HLRS, Universitaet Stuttgart
Copyright (C) 2011, 2012, 2013 Frank Scheiner

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

This product includes software developed by members of the DEISA project
www.deisa.org. DEISA is an EU FP7 integrated infrastructure initiative under
contract number RI-222919.

COPYRIGHT

version="0.4.0"

# path to configuration files (prefer system paths!)
# For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then

	gtransferConfigurationFilesPath="/etc/gtransfer"
	# gtransfer is installed in "/usr/bin", hence the base path is "/usr"
	gtransferBasePath="/usr"
	gtransferLibPath="$gtransferBasePath/share"

# For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#
#sed#	gtransferConfigurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	gtransferBasePath=<GTRANSFER_BASE_PATH>
#sed#	gtransferLibPath="$gtransferBasePath/lib"

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

# For user install in $HOME:
elif [[ -e "$HOME/opt/gtransfer" ]]; then

	gtransferConfigurationFilesPath="$HOME/.gtransfer"
	gtransferBasePath="$HOME/opt/gtransfer"
	gtransferLibPath="$gtransferBasePath/lib"

# For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then

	gtransferConfigurationFilesPath="$( dirname $BASH_SOURCE )/../etc/gtransfer"
	gtransferBasePath="$( dirname $BASH_SOURCE )/../"
	gtransferLibPath="$gtransferBasePath/lib"
fi

dparamConfigurationFile="$gtransferConfigurationFilesPath/dparam.conf"

__GLOBAL__requiredTools=( cat
                          sha1sum
                          cut
                          mkdir
                          touch
                          ln
                          sed
                          tar
                          globus-url-copy )


################################################################################
# FUNCTIONS
################################################################################
usageMsg()
{
	cat <<USAGE

usage: $(basename $0) [--help] ||

       $(basename $0) \\
        --create|-c [/path/to/files] [--automatic] \\
        --source|-s gsiftpSourceUrl \\
        --destination|-d gsiftpDestinationUrl \\
        --alias|-a alias \\
        [--configfile configurationFile]

       ||

       $(basename $0) \\
        --list|-l [/path/to/files] \\
        [--verbose|-v] \\
        [--configfile configurationFile]

       ||

       $(basename $0) \\
        --retrieve|-r [/path/to/files] \\
        [--quiet|-q] \\
        [--configfile configurationFile]

--help gives more information

USAGE
        return
}


helpMsg()
{
	cat <<HELP

$(versionMsg)

SYNOPSIS:

dparam --create|-c [/path/to/files] [--automatic] \\
       --source|-s gsiftpSourceUrl \\
       --destination|-d gsiftpDestinationUrl \\
       --alias|-a alias

dparam --list|-l [/path/to/files] [--verbose|-v]

dparam --retrieve|-r [/path/to/files] [--quiet|-q]

DESCRIPTION:

dparam is a helper script for gtransfer to support users in creating dparams,
listing available dparams and retrieve the latest dparams from a pre-configured
repository.

The options are as follows:

--create|-c [/path/to/files] [--automatic]
			Create a new dparam either in the user-provided
			path or - if no additional path is given - in the
			user dparams directory in:

			"$HOME/.gtransfer/.dparams"

			If "--automatic" is provided, tgftp auto-tuning will be
			used to determine the dparam.

--source|-s gsiftpSourceUrl
			Determine the source URL for the dparam without any path
			portion at the end.

			Example:

			gsiftp://saturn.milkyway.universe:2811


--destination|-d gsiftpDestinationUrl
			Determine the destination URL for the dparam without any
			path portion at the end.

			Example:

			gsiftp://pluto.milkyway.universe:2811

--alias|-a alias
			Determine the alias for the created dparam. dparam will
			create a link named "alias" to the dparam file which
			name is the sha1 hash of the source destination
			combination.

			NOTICE:

			Naming of the aliases is not restricted, but one's
			encouraged to use something like the following:

{{site|organization}_{resource|hostName|FQDN}|Local}--to--{site|organization}_{resource|hostName|FQDN}

--------------------------------------------------------------------------------

--list|-l [/path/to/files] [--verbose|-v]
			List all dparams available in the user-provided oath or
			- if no additional path is given - in the user and
			system dparams directories.

--------------------------------------------------------------------------------

--retrieve|-r [/path/to/files] [--quiet|-q]
			Retrieve the latest dparams available on a repository
			at:

			<$dParamsUrl>

			...and store them in the user-provided path or - if no
			additional path is given - in the user dparams
			directory. If a "--quiet|-q" is provided, then output is
			omitted and success/failure is only reported by the exit
			value.

--------------------------------------------------------------------------------

[--configfile configurationFile]
			Determine the name of the configuration file for dparam.
			If not set, this defaults to:

			"/opt/gtransfer/etc/dparam.conf" or

			"/etc/opt/gtransfer/dparam.conf" or

			"$HOME/.gtransfer/dparam.conf" in this order.

[--help]		Prints out a help message.

[--version|-V]		Prints out version information.

HELP
	return
}


versionMsg()
{
	echo "$(basename $0) - The default param helper script v$version"

	return
}


hashSourceDestination()
{
	# hashes the "source;destination" combination
	#
	# usage:
	# hashSourceDestination source destination
	#
	# NOTICE:
	# "source" and "destination" are URLs without path but with port
	# number!

	local sourceWithoutPath="$1"
	local destinationWithoutPath="$2"

	local dataPathName=$(echo "$sourceWithoutPath;$destinationWithoutPath" | sha1sum | cut -d ' ' -f 1)

	echo $dataPathName
}


createDParam()
{
	# creates a default param file and alias link
	#
	# usage:
	# createDParam source destination alias path [-a]
	#
	# returns:
	# 0 - success
	# 2 - default param already existing
	# everything else - error

	local sourceWithoutPath="$1"
	local destinationWithoutPath="$2"
	local dParamAlias="$3"
	local pathToDParams="$4"

	local dParamName="$( hashSourceDestination "$sourceWithoutPath" "$destinationWithoutPath" )"

	# check if default param dir is already existing and create it if not
	if [[ ! -e "$pathToDParams" ]]; then

		mkdir -p "$pathToDParams" || return 1
	fi

	# check if default param is already existing
	if [[ -e "$pathToDParams/$dParamName" ]]; then

		return 2
	fi

	# automatic default param creation wanted?
	if [[ "$5" == "-a" ]]; then

		# create data path file, link alias to it and start tgftp
		# auto-tuning to determine the default params
		touch "$pathToDParams/$dParamName" && \
		ln -s "$dParamName" "$pathToDParams/$dParamAlias" && \
		cat > "$pathToDParams/$dParamAlias" <<-EOF
			<source>
			$sourceWithoutPath
			</source>
			<destination>
			$destinationWithoutPath
			</destination>
			<gsiftp_params>
			$( tgftp -s $sourceWithoutPath/dev/zero -t $destinationWithoutPath/dev/null -a )
			</gsiftp_params>
		EOF

	else

		# create data path file and link alias to it
		touch "$pathToDParams/$dParamName" && \
		ln -s "$dParamName" "$pathToDParams/$dParamAlias" && \
		cat > "$pathToDParams/$dParamAlias" <<-EOF
			<source>
			$sourceWithoutPath
			</source>
			<destination>
			$destinationWithoutPath
			</destination>
			<gsiftp_params>
			# Enter params #
			</gsiftp_params>
		EOF

	fi

	return
}


listDParams()
{
	# list available default params
	#
	# usage:
	# listDParams [-v] [dParamsDir]

	local dParamsDir=""
	local verboseExec=1

	local source=""
	local destination=""
	local hashValue=""

	if [[ "$1" == "-v" ]]; then

		verboseExec=0
		shift 1
	fi

	if [[ "$1" != "-v" && "$1" != "--verbose" && "$1" != "" ]]; then

		dParamsDir="$1"
	fi

	if [[ -e "$dParamsDir" ]]; then

		for dParam in "$dParamsDir"/*; do

			# don't show links or backups (containing a '~' at the end of
			# the filename) and just continue if there are no dprams available.
			if [[ ! -L "$dParam" && \
			      "$dParam" != *~ && \
      			      "$dParam" != "${dParamsDir}/*" \
			]]; then
				source=$(xtractXMLAttributeValue "source" "$dParam")
				destination=$(xtractXMLAttributeValue "destination" "$dParam")
				dParams=$(xtractXMLAttributeValue "gsiftp_params" "$dParam")

				if [[ $verboseExec == 0 ]]; then

					hashValue="$(hashSourceDestination $source $destination): "
				fi

				echo "${hashValue}$source => $destination: \"$dParams\""
			fi
		done
	else
		echo "\"$dParamsDir\" not existing!"
		false
	fi

	return
}


xtractXMLAttributeValue()
{
	# determines the value between XML like tags
	#
	# NOTICE:
	# This function is limited to XML like files that have there tags in
	# separate lines.
	#
	# Example:
	# "<tag>value</tag>" doesn't work
	# "<tag>
	# value
	# </tag>" works
	#
	# usage:
	# xtractXMLAttributeValue attribute XMLFile
	#
	# attribute may contain arguments ('attribute arg="0"') or can be
	# without

	local attributeOpen="<$1>"

	local attributeClose="<\/${1%% *}>"

	local XMLFile="$2"

	# extract everything between and incl. given attribute tags | remove tags
	sed -n -e "/$attributeOpen/,/$attributeClose/p" <"$XMLFile" | sed -e "/^<.*>$/d"
}


retrieveDParams()
{
	# retrieves latest defautlt params available
	#
	# usage:
	# retrieveDataPaths [-q] dParamsDir

	local dParamsDir=""
	local verboseExec=0
	local gucVerbose=""
	local tarVerbose=""

	if [[ "$1" == "-q" ]]; then

		verboseExec=1
		shift 1
	fi

	if [[ verboseExec -eq 1 ]]; then

		gucVerbose=""

	elif [[ verboseExec -eq 0 ]]; then

		# make guc and tar verbose
		gucVerbose="-v"
		tarVerbose="-v"
	fi

	if [[ "$1" != "-q" && "$1" != "" ]]; then

		dParamsDir="$1"
	fi

	if [[ ! -e "$dParamsDir" ]]; then

		mkdir -p "$dParamsDir"
	fi

	#  retrieve data paths to data paths dir
	export GLOBUS_FTP_CLIENT_SOURCE_PASV=1

	cd "$dParamsDir" && \
	globus-url-copy $gucVerbose "$dParamsUrl" "file://$PWD/" && \
	tar $tarVerbose -xzf "$dParamsUrlPkg" && \
	rm "$dParamsUrlPkg"

	if [[ "$?" == "0" ]]; then

		return 0
	else
		return 1
	fi
}


use()
{
	# determines if a required tool/binary/etc. is available
	#
	# usage:
	# use "tool1" "tool2" "tool3" [...]

	local tools=$@

	local requiredToolNotAvailable=1

	for tool in $tools; do

		if ! which $tool &>/dev/null; then

			requiredToolNotAvailable=0
			echo "ERROR: Required tool \"$tool\" can not be found!"
		fi
	done

	if [[ $requiredToolNotAvailable == 0 ]]; then

		return 1
	else
		return 0
	fi
}


################################################################################
# MAIN
################################################################################
# test if all required tools are available
if ! use "${__GLOBAL__requiredTools[@]}"; then

	exit 1
fi

# correct number of params?
if [[ "$#" -lt "1" ]]; then

	# no, so output a usage message
	usageMsg
	exit 1
fi

# read in all parameters
while [[ "$1" != "" ]]; do

	#  only valid params used?
	if [[ "$1" != "--help" && \
	      "$1" != "--version" && "$1" != "-V" && \
	      "$1" != "--create" && "$1" != "-c" && \
	      "$1" != "--alias" && "$1" != "-a" && \
	      "$1" != "--source" && "$1" != "-s" && \
	      "$1" != "--destination" && "$1" != "-d" && \
	      "$1" != "--verbose" && "$1" != "-v" && \
	      "$1" != "--quiet" && "$1" != "-q" && \
	      "$1" != "--list" && "$1" != "-l" && \
	      "$1" != "--retrieve" && "$1" != "-r" && \
	      "$1" != "--automatic" && \
	      "$1" != "--configfile" \
	]]; then
		# no, so output a usage message
		usageMsg
		exit 1
	fi

	# "--help"
	if [[ "$1" == "--help" ]]; then

		if [[ "$helpMsgSet" != "0" ]]; then

			helpMsgSet="0"
		fi

		break

	# "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then

		versionMsg
		exit 0

	# "--verbose|-v"
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]]; then

		if [[ $verboseExecSet != 0 ]]; then

			shift 1
			verboseExec=0
			verboseExecSet=0
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--verbose|-v\" cannot be used multiple times!"
			exit 1
		fi

	# "--quiet|-q"
	elif [[ "$1" == "--quiet" || "$1" == "-q" ]]; then

		if [[ $quietExecSet != 0 ]]; then

			shift 1
			quietExec=0
			quietExecSet=0
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--quiet|-q\" cannot be used multiple times!"
			exit 1
		fi

	# "--automatic"
	elif [[ "$1" == "--automatic" ]]; then

		if [[ $automaticExecSet != 0 ]]; then

			shift 1
			automaticExec=0
			automaticExecSet=0
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--automatic\" cannot be used multiple times!"
			exit 1
		fi

	# "--source|-s gsiftpSourceUrl"
	elif [[ "$1" == "--source" || "$1" == "-s" ]]; then

		if [[ "$gsiftpSourceUrlSet" != "0" ]]; then

			shift 1
			gsiftpSourceUrl="$1"
			gsiftpSourceUrlSet="0"
			shift 1
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--source|-s\" cannot be used multiple times!"
			exit 1
		fi

	# "--destination|-d gsiftpDestinationUrl"
	elif [[ "$1" == "--destination" || "$1" == "-d" ]]; then

		if [[ "$gsiftpDestinationUrlSet" != "0" ]]; then

			shift 1
			gsiftpDestinationUrl="$1"
			gsiftpDestinationUrlSet="0"
			shift 1
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--destination|-d\" cannot be used multiple times!"
			exit 1
		fi

	# "--create|-c [/path/to/file]"
	elif [[ "$1" == "--create" || "$1" == "-c" ]]; then

		if [[ "$createDParamSet" != "0" ]]; then

			shift 1

			# path provided?
			if [[ "${1:0:1}" != "-" ]]; then

				# yes
				dParamsDir="$1"
				shift 1
			else
				dParamsDir=""
			fi

			createDParamSet="0"
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--create|-c\" cannot be used multiple times!"
			exit 1
		fi

	# "--list|-l [/path/to/file]"
	elif [[ "$1" == "--list" || "$1" == "-l" ]]; then

		if [[ "$listDParamsSet" != "0" ]]; then

			shift 1

			# path provided?
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then

				# yes
				dParamsDir="$1"
				shift 1
			else
				dParamsDir=""
			fi

			listDParamsSet="0"
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--list|-l\" cannot be used multiple times!"
			exit 1
		fi

	# "--retrieve|-r [/path/to/file]"
	elif [[ "$1" == "--retrieve" || "$1" == "-r" ]]; then

		if [[ "$retrieveDParamsSet" != "0" ]]; then

			shift 1

			# path provided?
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then

				# yes
				dParamsDir="$1"
				shift 1
			else
				dParamsDir=""
			fi

			retrieveDParamsSet="0"
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--retrieve|-r\" cannot be used multiple times!"
			exit 1
		fi

	# "--alias|-a alias"
	elif [[ "$1" == "--alias" || "$1" == "-a" ]]; then

		if [[ "$aliasSet" != "0" ]]; then

			shift 1
			alias="$1"
			aliasSet="0"
			shift 1
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--alias|-a\" cannot be used multiple times!"
			exit 1
		fi

	# "--configfile"
	elif [[ "$1" == "--configfile" ]]; then

		if [[ $dparamConfigurationFileSet != 0 ]]; then

			shift 1
			dparamConfigurationFile="$1"
			dparamConfigurationFileSet=0
			shift 1
		else
			# duplicate usage of this parameter
			echo "ERROR: The parameter \"--configfile\" cannot be used multiple times!"
			exit 1
		fi
	fi
done

# load configuration file
if [[ -e "$dparamConfigurationFile" ]]; then

	. "$dparamConfigurationFile"
else
	echo "ERROR: dparam configuration file missing!"
	exit 1
fi

# HELP
if [[ "$helpMsgSet" == "0" ]]; then

	helpMsg
	exit 0

# CREATE mode
elif [[ "$createDParamSet" == "0" ]]; then

	if [[ "$gsiftpSourceUrlSet" != "0" || \
	      "$gsiftpDestinationUrlSet" != "0" || \
	      "$aliasSet" != "0" \
	]]; then
		# no, so output a usage message
		usageMsg
		exit 1
	else
		if [[ "$dParamsDir" == "" ]]; then

			dParamsDir="$defaultDParamsDir"
		fi

		if [[ $automaticExecSet == 0 ]]; then

			createDParam "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$alias" "$dParamsDir" "-a"
		else
			createDParam "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$alias" "$dParamsDir"
		fi

		returnValue="$?"

		if [[ "$returnValue" == "2" ]]; then

			echo "ERROR: Default params file already exists. For changes please edit \"$dParamsDir/$alias\" directly!"
			exit 1

		elif [[ "$returnValue" != "0" ]]; then

			echo "ERROR: Problems during default params creation!"
			exit 1
		else
			if [[ "$EDITOR" != "" && $automaticExecSet != 0 ]]; then

				$EDITOR $dParamsDir/$alias
				echo "INFO: Default params \"$dParamsDir/$alias\" was created."

			elif [[ $automaticExecSet == 0 ]]; then

				echo "INFO: Default params \"$dParamsDir/$alias\" was created"

			elif [[ $automaticExecSet != 0 ]]; then

				echo "INFO: Default params \"$dParamsDir/$alias\" was created. Please use your preferred editor to edit the default params file."
			fi
		fi

		exit "$?"
	fi

# LIST mode
elif [[ "$listDParamsSet" == "0" ]]; then

	if [[ "$dParamsDir" == "" ]]; then

		if [[ "$verboseExecSet" == "0" ]]; then

			echo "User dparams ($defaultDParamsDir):"
			listDParams -v "$defaultDParamsDir"
			echo "System dparams ($systemDParamsDir):"
			listDParams -v "$systemDParamsDir"
		else
			echo "User dparams:"
			listDParams -v "$defaultDParamsDir"
			echo "System dparams:"
			listDParams -v "$systemDParamsDir"
		fi
	else
		if [[ "$verboseExecSet" == "0" ]]; then

			listDParams -v "$dParamsDir"
		else
			listDParams "$dParamsDir"
		fi
	fi

	exit $?

# RETRIEVE mode
elif [[ "$retrieveDParamsSet" == "0" ]]; then

	if ! use wget tar; then

		echo "ERROR: Cannot run without required tools (wget, tar)! Exiting now!"
		exit 1
	fi

	if [[ "$dParamsDir" == "" ]]; then

		dParamsDir="$defaultDParamsDir"
	fi

	if [[ "$quietExecSet" == "0" ]]; then

		retrieveDParams -q "$dParamsDir"
		returnValue="$?"
	else
		retrieveDParams "$dParamsDir"
		returnValue="$?"
	fi

	if [[ "$returnValue" != "0" && "$quietExecSet" == "0" ]]; then

		exit 1

	elif [[ "$returnValue" != "0" ]]; then

		echo "ERROR: Problems during dparams retrieval!"
		exit 1
	else
		exit 0
	fi

else
	usageMsg
	exit 1
fi
