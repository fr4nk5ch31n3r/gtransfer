#!/bin/bash

#  dpath - data path creation, editing, listing, etc.

:<<COPYRIGHT

Copyright (C) 2011 Frank Scheiner, HLRS, Universitaet Stuttgart
Copyright (C) 2011, 2012 Frank Scheiner

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

version="0.1.0"

#  path to configuration files (prefer system paths!)
#  For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then
        gtransferConfigurationFilesPath="/etc/gtransfer"
        #  gtransfer is installed in "/usr/bin", hence the base path is "/usr"
        gtransferBasePath="/usr"
        gtransferLibPath="$gtransferBasePath/lib/gtransfer"

#  For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#	gtransferConfigurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	gtransferBasePath=<GTRANSFER_BASE_PATH>
#sed#	gtransferLibPath="$gtransferBasePath/lib"

#  According to FHS 2.3, configuration files for packages located in "/opt" have
#+ to be placed here (if you use a provider super dir below "/opt" for the
#+ gtransfer files, please also use the same provider super dir below
#+ "/etc/opt").
#elif [[ -e "/etc/opt/<PROVIDER>/gtransfer" ]]; then
#	gtransferConfigurationFilesPath="/etc/opt/<PROVIDER>/gtransfer"
#	gtransferBasePath="/opt/<PROVIDER>/gtransfer"
#	gtransferLibPath="$gtransferBasePath/lib"
elif [[ -e "/etc/opt/gtransfer" ]]; then
        gtransferConfigurationFilesPath="/etc/opt/gtransfer"
        gtransferBasePath="/opt/gtransfer"
        gtransferLibPath="$gtransferBasePath/lib"

#  For user install in $HOME:
elif [[ -e "$HOME/.gtransfer" ]]; then
        gtransferConfigurationFilesPath="$HOME/.gtransfer"
        gtransferBasePath="$HOME/opt/gtransfer"
        gtransferLibPath="$gtransferBasePath/lib"

#  For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then
	gtransferConfigurationFilesPath="$( dirname $BASH_SOURCE )/../etc"
	gtransferBasePath="$( dirname $BASH_SOURCE )/../"
	gtransferLibPath="$gtransferBasePath/lib"
fi

dpathConfigurationFile="$gtransferConfigurationFilesPath/dpath.conf"

__GLOBAL__sourcesIndexFile="sources.index"
__GLOBAL__destinationsIndexFile="destinations.index"
__GLOBAL__requiredTools=( cat 
                          sha1sum 
                          cut 
                          mkdir 
                          touch 
                          ln 
                          grep 
                          sed 
                          tar 
                          globus-url-copy 
                          sort )

#USAGE##########################################################################
usageMsg()
{
        cat <<USAGE

usage: dpath [--help]

       dpath --create|-c [/path/to/files] --source|-s gsiftpSourceUrl --destination|-d gsiftpDestinationUrl --alias|-a alias [--dpath-template|-t dpathTemplate] [--configfile configurationFile]

       dpath --batch-create|-b [/path/to/files] --hosts|-h hostsFile [--dpath-template|-t dpathTemplate] [--configfile configurationFile]

       dpath --list|-l [/path/to/files] [--verbose|-v] [--configfile configurationFile]

       dpath --retrieve|-r [/path/to/files] [--quiet|-q] [--configfile configurationFile]

--help gives more information

USAGE
        return
}
#END_USAGE######################################################################

#HELP###########################################################################
helpMsg()
{
	cat <<HELP

$(versionMsg)

SYNOPSIS:

dpath --create|-c [/path/to/files] --source|-s gsiftpSourceUrl --destination|-d gsiftpDestinationUrl --alias|-a alias [--dpath-template|-t dpathTemplate] [--configfile configurationFile]

dpath --batch-create|-b [/path/to/files] --hosts|-h hostsFile [--dpath-template|-t dpathTemplate] [--configfile configurationFile]

dpath --list|-l [/path/to/files] [--verbose|-v] [--configfile configurationFile]

dpath --retrieve|-r [/path/to/files] [--quiet|-q] [--configfile configurationFile]

DESCRIPTION:

dpath is a helper script for gtransfer to support users in creating dpaths,
listing available dpaths and retrieve the latest dpaths from a pre-configured
repository.

The options are as follows:

--create|-c [/path/to/files]
			Create a new dpath either in the user-provided path
			or - if no additional path is given - in the user dpaths
			directory in:

			"\$HOME/.gtransfer/dpaths".

--source|-s gsiftpSourceUrl
			Determine the source URL for the dpath without any path
			portion at the end.

			Example:

			gsiftp://saturn.milkyway.universe:2811

--destination|-d gsiftpDestinationUrl
			Determine the destination URL for the dpath without any
			path portion at the end.

			Example:

			gsiftp://pluto.milkyway.universe:2811

--alias|-a alias
			Determine the alias for the created dpath. dpath will
			create a link named "alias" to the dpath which name is
			the SHA1 hash of the source destination combination.

			NOTICE:

			Naming of the aliases is not restricted, but one's
			encouraged to use something like the following:

{{site|organization}_{resource|hostName|FQDN}|Local}--to--{site|organization}_{resource|hostName|FQDN}

[--dpath-template|-t dpathTemplate]
			When provided, dpath will use the given template for
			dpath creation. The following variables are expanded
			during dpath creation:
			
			\$sourceWithoutPath => gsiftpSourceUrl => the host
			address of the source site
			
			\$destinationWithoutPath => gsiftpDestinationUrl => the
			host address of the destination site

--------------------------------------------------------------------------------

--batch-create|-b [/path/to/files]
			Create dpaths in batch mode either in the user-provided
			path or - if no additional path is given - in the user
			dpaths directory in:

			"$HOME/.gtransfer/dpaths".
			
			When used, dpath will create dpaths for all possible
			connections between the hosts given in the hostsFile and
			omit connections between the same hosts.
			
--hosts|-h hostsFile    Set the file name for the file containing the host
 			addresses for which dpaths should be created. The format
 			of each line in this file is as follows:

 			<PROTOCOL>://hostname.domain.tld:<PORT>

[--dpath-template|-t dpathTemplate]
			When provided, dpath will use the given template for
			dpath creation. The following variables are expanded
			during dpath creation:
			
			\$sourceWithoutPath => gsiftpSourceUrl => the host
			address of the source site
			
			\$destinationWithoutPath => gsiftpDestinationUrl => the
			host address of the destination site

--------------------------------------------------------------------------------

--list|-l [/path/to/files] [--verbose|-v]
			List all dpaths available in the user-provided path or -
			if no additional path is given - in the user and system
			dpaths directories.

--------------------------------------------------------------------------------

--list-sources [/path/to/dataPaths]
			List all sources from the dpaths in the user-provided
			path or - if no additional path is given - in the user
			and system dpaths directories.
			
--list-destinations [/path/to/dataPaths]
			List all destinations from the dpaths in the user-
			provided path or - if no additional path is given - in
			the user and system dpaths directories.

--------------------------------------------------------------------------------

--retrieve|-r [/path/to/files] [--quiet|-q]
			Retrieve the latest dpaths available on a repository at:

			<$dataPathsUrl>

			...and store them in the user-provided path or - if no
			additional path is given - in the user dpaths directory.
			If a "--quiet|-q" is provided, then output is omitted
			and success/failure is only reported by the exit value. 

--------------------------------------------------------------------------------

[--configfile configurationFile]
			Determine the name of the configuration file for dpath.
			If not set, this defaults to:

			"/opt/gtransfer/etc/dpath.conf" or

			"/etc/opt/gtransfer/dpath.conf" or

			"\$HOME/.gtransfer/dpath.conf" in this order.

[--help]                Prints out this help message.

[--version|-V]          Prints out version information

HELP
	return
}
#END_HELP#######################################################################

#VERSION########################################################################
versionMsg()
{
	echo "$(basename $0) - The data path helper script v$version"

        return
}
#END_VERSION####################################################################

hashSourceDestination()
{
	#  hashes the "source;destination" combination
	#
	#  usage:
	#+ hashSourceDestination source destination
	#
	#  NOTICE:
	#+ "source" and "destination" are URLs without path but with port
	#+ number!

	local sourceWithoutPath="$1"
	local destinationWithoutPath="$2"

	local dataPathName=$(echo "$sourceWithoutPath;$destinationWithoutPath" | sha1sum | cut -d ' ' -f 1)

	echo $dataPathName
}

createDataPath()
{
	#  creates a data path file and alias link
	#
	#  usage:
	#+ createDataPath source destination alias path [dpathTemplate]
	#
	#  returns:
	#+ 0 - success
	#+ 2 - data path already existing
	#+ everything else - error
	
	local sourceWithoutPath="$1"
	local destinationWithoutPath="$2"
	local dataPathAlias="$3"
	local pathToDataPaths="$4"
	local dpathTemplate="$5"

	local dataPathName="$( hashSourceDestination "$sourceWithoutPath" "$destinationWithoutPath" )"

	#  check if data path dir is already existing and create it if not
	if [[ ! -e "$pathToDataPaths" ]]; then
		mkdir -p "$pathToDataPaths" || return 1
	fi

	#  check if data path is already existing
	if [[ -e "$pathToDataPaths/$dataPathName" ]]; then
		return 2
	fi

	#  create data path file and link alias to it
	if [[ "$dpathTemplate" == "" ]]; then
		touch "$pathToDataPaths/$dataPathName" && \
		ln -s "$dataPathName" "$pathToDataPaths/$dataPathAlias" && \
		cat > "$pathToDataPaths/$dataPathAlias" <<-EOF
		<source>
		$sourceWithoutPath
		</source>
		<destination>
		$destinationWithoutPath
		</destination>
		<path metric="0">
		$sourceWithoutPath;$destinationWithoutPath
		</path>
		<path metric="1">
		$sourceWithoutPath;# Enter transit site 1 #
		# Enter transit site 1 #;# Enter transit site 2 #
		# Enter transit site 2 #;$destinationWithoutPath
		</path>
		EOF
	else
		dataPath=$( cat "$dpathTemplate" )
		#  expand sourceWithoutPath
		dataPath=$( echo "${dataPath//\$sourceWithoutPath/${sourceWithoutPath}}" )
		#  expand destinationWithoutPath
		dataPath=$( echo "${dataPath//\$destinationWithoutPath/${destinationWithoutPath}}" )		
		
		touch "$pathToDataPaths/$dataPathName" && \
		ln -s "$dataPathName" "$pathToDataPaths/$dataPathAlias" && \
		echo "$dataPath" > "$pathToDataPaths/$dataPathAlias"
	fi
	
	if [[ $? -eq 0 ]]; then
		#  add source and destination to index files
		
		#  NOTICE: If one provides the input for grep via stdin
		#+ (<inputFile), then if the input file does not exist, the
		#+ shell will print out an error message, as the redirection
		#+ cannot be made. Therefore the input file is provided directly
		#+ and any grep output is omitted.
		if ! grep "$sourceWithoutPath" "$pathToDataPaths/$__GLOBAL__sourcesIndexFile" &>/dev/null; then
			echo "$sourceWithoutPath" >>"$pathToDataPaths/$__GLOBAL__sourcesIndexFile"
		fi
		if ! grep "$destinationWithoutPath" "$pathToDataPaths/$__GLOBAL__destinationsIndexFile" &>/dev/null; then
			echo "$destinationWithoutPath" >>"$pathToDataPaths/$__GLOBAL__destinationsIndexFile"
		fi
		return
	else
		return 1
	fi
}

listDataPaths()
{
	#  list available data paths
	#
	#  usage:
	#+ listDataPaths [-v] dataPathsDir

	local dataPathsDir=""
	local verboseExec=1

	local source=""
	local destination=""
	local hashValue=""

	if [[ "$1" == "-v" ]]; then
		verboseExec=0
		#echo "shifting"
		shift 1
	fi

	#echo "$1"

	if [[ "$1" != "-v" && "$1" != "--verbose" && "$1" != "" ]]; then
		dataPathsDir="$1"
	fi

	#echo "$@ - $dataPathsDir"
	if [[ -e "$dataPathsDir" ]]; then
		for dataPath in "$dataPathsDir"/*; do
			#  don't show links or backups (containing a '~' at the end of
			#+ the filename)
			if [[ ! -L "$dataPath" && \
			      "$dataPath" != *~ && \
			      "$dataPath" != *index \
			]]; then
				source=$(xtractXMLAttributeValue "source" "$dataPath")
				destination=$(xtractXMLAttributeValue "destination" "$dataPath")
				if [[ $verboseExec == 0 ]]; then
					hashValue="$(hashSourceDestination $source $destination): "
				fi
	
				echo "${hashValue}${source} => ${destination}"
			fi
		done
	else
		echo "\"$dataPathsDir\" not existing!"
		false
	fi

	return
}


listSources()
{
	#  list all sources
	#
	#  usage:
	#+ listSources dataPathsDir
	
	local dataPathsDir="$1"

	local source=""

	if [[ -e "$dataPathsDir" ]]; then
		#  if index file is available, just print its contents
		if [[ -e "$dataPathsDir/$__GLOBAL__sourcesIndexFile" ]]; then
			cat "$dataPathsDir/$__GLOBAL__sourcesIndexFile"
		else
			for dataPath in "$dataPathsDir"/*; do
				#  don't show links or backups (containing a '~' at the end of
				#+ the filename)
				if [[ ! -L "$dataPath" && \
				      "$dataPath" != *~ && \
				      "$dataPath" != *index \
				]]; then
					source=$(xtractXMLAttributeValue "source" "$dataPath")
					#sourceAlias=$(xtractXMLAttributeValue "source-alias" $dataPathsDir/$dataPath)
					echo "${source}"
					#[[ ! -z "$sourceAlias" ]] && echo "$sourceAlias"
				fi
			done
		fi
	else
		#echo "ERROR: \"$dataPathsDir\" not existing!"
		false
	fi

	return
}


listDestinations()
{
	#  list all Destinations
	#
	#  usage:
	#+ listDestinations dataPathsDir
	
	local dataPathsDir="$1"

	local destination=""

	if [[ -e "$dataPathsDir" ]]; then
		#  if index file is available, just print its contents
		if [[ -e "$dataPathsDir/$__GLOBAL__destinationsIndexFile" ]]; then
			cat "$dataPathsDir/$__GLOBAL__destinationsIndexFile"
		else
			for dataPath in "$dataPathsDir"/*; do
				#  don't show links or backups (containing a '~' at the end of
				#+ the filename)
				if [[ ! -L "$dataPath" && \
				      "$dataPath" != *~ && \
				      "$dataPath" != *index \
				]]; then
					destination=$(xtractXMLAttributeValue "destination" $dataPathsDir/$dataPath)
					#destinationAlias=$(xtractXMLAttributeValue "destination-alias" $dataPathsDir/$dataPath)
					echo "$destination"
					#[[ ! -z "$destinationAlias" ]] && echo "$destinationAlias"
				fi
			done
		fi
	else
		#echo "ERROR: \"$dataPathsDir\" not existing!"
		false
	fi

	return
}

xtractXMLAttributeValue()
{
	#  determines the value between XML like tags
	#
	#  NOTICE:
	#+ This function is limited to XML like files that have there tags in
	#+ separate lines.
	#+
	#+ Example:
	#+ "<tag>value</tag>" doesn't work
	#+ "<tag>
	#+ value
	#+ </tag>" works
	#
	#  usage:
	#+ xtractXMLAttributeValue attribute XMLFile
	#
	#  attribute may contain arguments ('attribute arg="0"') or can be
	#+ without

	local attributeOpen="<$1>"
	
	#echoDebug "stderr" "DEBUG1" "Open: $attributeOpen"

	local attributeClose="<\/${1%% *}>"

	#echoDebug "stderr" "DEBUG1" "Close: $attributeClose"

	local XMLFile="$2"

	#echoDebug "stderr" "DEBUG1" "$XMLFile"

	#  extract everything between and incl. given attribute tags| remove tags    
	sed -n -e "/$attributeOpen/,/$attributeClose/p" <"$XMLFile" | sed -e "/^<.*>$/d"
}

retrieveDataPaths()
{
	#  retrieves latest data paths available
	#
	#  usage:
	#+ retrieveDataPaths [-q] dataPathsDir

	local dataPathsDir=""
	local verboseExec=0
	local wgetVerbose=""
	local tarVerbose=""

	if [[ "$1" == "-q" ]]; then
		verboseExec=1
		shift 1
	fi

	if [[ verboseExec -eq 1 ]]; then
		#  make wget quiet
		#wgetVerbose="-q"
		gucVerbose=""
	elif [[ verboseExec -eq 0 ]]; then
		#  make wget and tar verbose
		#wgetVerbose="-v"
		gucVerbose="-v"
		tarVerbose="-v"
	fi

	if [[ "$1" != "-q" && "$1" != "" ]]; then
		dataPathsDir="$1"
	fi

	if [[ ! -e "$dataPathsDir" ]]; then
		mkdir -p "$dataPathsDir"
	fi

	#  retrieve data paths to data paths dir
	#cd "$dataPathsDir" && \
	#wget $wgetVerbose "$dataPathsUrl" && \
	#tar $tarVerbose -xzf "$dataPathsUrlPkg" && \
	#rm "$dataPathsUrlPkg"
	
	export GLOBUS_FTP_CLIENT_SOURCE_PASV=1
	
	cd "$dataPathsDir" && \
	globus-url-copy $gucVerbose "$dataPathsUrl" "file://$PWD/" && \
	tar $tarVerbose -xzf "$dataPathsUrlPkg" && \
	rm "$dataPathsUrlPkg"
	
	if [[ "$?" == "0" ]]; then
		return 0
	else
		return 1
	fi

}

use()
{
	#  determines if a required tool/binary/etc. is available
	#
	#  usage:
	#+ use "tool1" "tool2" "tool3" [...]

	local tools=$@

	local requiredToolNotAvailable=1

	for tool in $tools; do
		#echo "$tool"
		if ! hash $tool &>/dev/null; then
			requiredToolNotAvailable=0
			echo "ERROR: Required tool \"$tool\" can not be found!"
		fi
	done

	if [[ $requiredToolNotAvailable == 0 ]]; then
		return 1
	fi
}


reindexDataPaths()
{
	#  list available data paths
	#
	#  usage:
	#+ reindexDataPaths [-v] dataPathsDir

	local dataPathsDir=""

	local source=""
	local destination=""
	local hashValue=""

	if [[ "$1" == "-v" ]]; then
		verboseExec=0
		#echo "shifting"
		shift 1
	fi

	#echo "$1"

	if [[ "$1" != "-v" && "$1" != "--verbose" && "$1" != "" ]]; then
		dataPathsDir="$1"
	fi

	#echo "$@ - $dataPathsDir"
	if [[ -e "$dataPathsDir" ]]; then
		for dataPath in "$dataPathsDir"/*; do
			#  don't show links or backups (containing a '~' at the end of
			#+ the filename)
			if [[ ! -L "$dataPath" && \
			      "$dataPath" != *~ && \
			      "$dataPath" != *.index* \
			]]; then
				source=$(xtractXMLAttributeValue "source" "$dataPath")
				destination=$(xtractXMLAttributeValue "destination" "$dataPath")
				if [[ $verboseExec == 0 ]]; then
					hashValue="$(hashSourceDestination $source $destination): "
				fi
	
				echo "${hashValue}${source} => ${destination}"
				
				echo "${source}" >> "$dataPathsDir/${__GLOBAL__sourcesIndexFile}.#dpath#tmp#"
				echo "${destination}" >> "$dataPathsDir/${__GLOBAL__destinationsIndexFile}.#dpath#tmp#"
			fi
		done
	else
		echo "\"$dataPathsDir\" not existing!"
		return 1
	fi

	sort -u "$dataPathsDir/${__GLOBAL__sourcesIndexFile}.#dpath#tmp#" > "$dataPathsDir/${__GLOBAL__sourcesIndexFile}"
	sort -u "$dataPathsDir/${__GLOBAL__destinationsIndexFile}.#dpath#tmp#" > "$dataPathsDir/${__GLOBAL__destinationsIndexFile}"
	rm -f "$dataPathsDir/${__GLOBAL__sourcesIndexFile}.#dpath#tmp#" \
	      "$dataPathsDir/${__GLOBAL__destinationsIndexFile}.#dpath#tmp#"
	      
	return
}


#MAIN###########################################################################

#  test if all required tools are available
if ! use "${__GLOBAL__requiredTools[@]}"; then
	exit 1
fi

#  correct number of params?
if [[ "$#" -lt "1" ]]; then
   # no, so output a usage message
   usageMsg
   exit 1
fi

# read in all parameters
while [[ "$1" != "" ]]; do

	#  only valid params used?
	#
	#  NOTICE:
	#  This was added to prevent high speed loops
	#+ if parameters are mispositioned.
	if [[   "$1" != "--help" && \
		"$1" != "--version" && "$1" != "-V" && \
		"$1" != "--create" && "$1" != "-c" && \
		"$1" != "--alias" && "$1" != "-a" && \
		"$1" != "--source" && "$1" != "-s" && \
		"$1" != "--destination" && "$1" != "-d" && \
		"$1" != "--verbose" && "$1" != "-v" && \
		"$1" != "--quiet" && "$1" != "-q" && \
		"$1" != "--list" && "$1" != "-l" && \
		"$1" != "--list-sources" && \
		"$1" != "--list-destinations" && \
		"$1" != "--retrieve" && "$1" != "-r" && \
		"$1" != "--batch-create" && "$1" != "-b" && \
		"$1" != "--hosts" && "$1" != "-h" && \
		"$1" != "--dpath-template" && "$1" != "-t" && \
		"$1" != "--reindex" && \
		"$1" != "--configfile" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit 1   
	fi

	#  "--help"
	if [[ "$1" == "--help" ]]; then
		if [[ "$helpMsgSet" != "0" ]]; then		
			helpMsgSet="0"
		fi
	
		break

	#  "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then
		versionMsg
		exit 0

	#  "--verbose|-v"
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
		if [[ $verboseExecSet != 0 ]]; then
			shift 1
			verboseExec=0
			verboseExecSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--verbose|-v\" cannot be used multiple times!"
			exit 1
		fi

	#  "--quiet|-q"
	elif [[ "$1" == "--quiet" || "$1" == "-q" ]]; then
		if [[ $quietExecSet != 0 ]]; then
			shift 1
			quietExec=0
			quietExecSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--quiet|-q\" cannot be used multiple times!"
			exit 1
		fi
		
	#  "--reindex"
	elif [[ "$1" == "--reindex" ]]; then
		if [[ $reindexSet != 0 ]]; then
			shift 1
			reindex=0
			reindexSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--reindex\" cannot be used multiple times!"
			exit 1
		fi

	#  "--source|-s gsiftpSourceUrl"
	elif [[ "$1" == "--source" || "$1" == "-s" ]]; then
		if [[ "$gsiftpSourceUrlSet" != "0" ]]; then
			shift 1
			gsiftpSourceUrl="$1"
			gsiftpSourceUrlSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--source|-s\" cannot be used multiple times!"
			exit 1
		fi

	#  "--destination|-d gsiftpDestinationUrl"
	elif [[ "$1" == "--destination" || "$1" == "-d" ]]; then
		if [[ "$gsiftpDestinationUrlSet" != "0" ]]; then
			shift 1
			gsiftpDestinationUrl="$1"
			gsiftpDestinationUrlSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--destination|-d\" cannot be used multiple times!"
			exit 1
		fi

	#  "--create|-c [/path/to/files]"
	elif [[ "$1" == "--create" || "$1" == "-c" ]]; then
		if [[ "$createDataPathSet" != "0" ]]; then
			shift 1
			#  path provided?
			if [[ "${1:0:1}" != "-" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			createDataPathSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--create|-c\" cannot be used multiple times!"
			exit 1
		fi
		
	#  "--batch-create|-b [/path/to/files]"
	elif [[ "$1" == "--batch-create" || "$1" == "-b" ]]; then
		if [[ "$batchCreateDataPathsSet" != "0" ]]; then
			shift 1
			#  path provided?
			if [[ "${1:0:1}" != "-" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			batchCreateDataPathsSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--batch-create|-b\" cannot be used multiple times!"
			exit 1
		fi

	#  "--list|-l [/path/to/dataPaths]"
	elif [[ "$1" == "--list" || "$1" == "-l" ]]; then
		if [[ "$listDataPathsSet" != "0" ]]; then		
			shift 1
			#  path provided?		
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			listDataPathsSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--list|-l\" cannot be used multiple times!"
			exit 1
		fi
		
	#  "--list-sources [/path/to/dataPaths]"
	elif [[ "$1" == "--list-sources" ]]; then
		if [[ "$listSourcesSet" != "0" ]]; then
			shift 1
			#  path provided?		
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			listSourcesSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--list-sources\" cannot be used multiple times!"
			exit 1
		fi

	#  "--list-destinations [/path/to/dataPaths]"
	elif [[ "$1" == "--list-destinations" ]]; then
		if [[ "$listDestinationsSet" != "0" ]]; then
			shift 1
			#  path provided?		
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			listDestinationsSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--list-destinations\" cannot be used multiple times!"
			exit 1
		fi

	#  "--retrieve|-r [/path/to/dataPaths]"
	elif [[ "$1" == "--retrieve" || "$1" == "-r" ]]; then
		if [[ "$retrieveDataPathsSet" != "0" ]]; then
			shift 1
			#  path provided?		
			if [[ "${1:0:1}" != "-" && "$1" != "" ]]; then
				#  yes
				dataPathsDir="$1"
				shift 1
			else
				dataPathsDir=""
			fi
			retrieveDataPathsSet="0"
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--retrieve|-r\" cannot be used multiple times!"
			exit 1
		fi
		

	#  "--alias|-a alias"
	elif [[ "$1" == "--alias" || "$1" == "-a" ]]; then
		if [[ "$aliasSet" != "0" ]]; then
			shift 1
			alias="$1"
			aliasSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--alias|-a\" cannot be used multiple times!"
			exit 1
		fi

	#  "--configfile configurationFile"
	elif [[ "$1" == "--configfile" ]]; then
		if [[ $dpathConfigurationFileSet != 0 ]]; then
			shift 1
			dpathConfigurationFile="$1"
			dpathConfigurationFileSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--configfile\" cannot be used multiple times!"
			exit 1
		fi
		
	#  "--hosts|-h hostsFile"
	elif [[ "$1" == "--hosts" || "$1" == "-h" ]]; then
		if [[ $hostsFileSet != 0 ]]; then
			shift 1
			hostsFile="$1"
			hostsFileSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--hosts\" cannot be used multiple times!"
			exit 1
		fi
		
	#  "[--dpath-template|-t dpathTemplate]
	elif [[ "$1" == "--dpath-template" || "$1" == "-t" ]]; then
		if [[ $dpathTemplateSet != 0 ]]; then
			shift 1
			dpathTemplate="$1"
			dpathTemplateSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--dpath-template\" cannot be used multiple times!"
			exit 1
		fi

	fi
done

#  load configuration file
if [[ -e "$dpathConfigurationFile" ]]; then
	. "$dpathConfigurationFile"
else
	echo "ERROR: dpath configuration file missing!"
	exit 1
fi

#  HELP
if [[ "$helpMsgSet" == "0" ]]; then
	helpMsg
	exit 0

#  REINDEX mode
elif [[ "$reindexSet" == "0" ]]; then
	if [[ "$dataPathsDir" == "" ]]; then
		dataPathsDir="$defaultDataPathsDir"
	fi
	
	if [[ "$verboseExecSet" == "0" ]]; then
		reindexDataPaths -v "$dataPathsDir"
	else
		reindexDataPaths "$dataPathsDir"
	fi
	
	exit

#  BATCH CREATE mode
elif [[ "$batchCreateDataPathsSet" == "0" ]]; then
	if [[ "$hostsFileSet" != "0" ]]; then
		#  no, so output a usage message
		usageMsg
		exit 1
	else
		if [[ "$dataPathsDir" == "" ]]; then
			dataPathsDir="$defaultDataPathsDir"
		fi

		declare -a hosts

		hosts=( $( cat "$hostsFile" ) )
		
		maxIndex=${#hosts[@]}
		
		#echo "($$) DEBUG: maxIndex=\"$maxIndex\"" 1>&2
		
		for index in $( seq 0 $maxIndex ); do
			for index2 in $( seq 0 $maxIndex ); do
				if [[ $index -eq $index2 ]]; then
					continue
				else
					gsiftpSourceUrl=${hosts[$index]}
					if [[ "$gsiftpSourceUrl" == "" ]]; then
						continue
					fi
					gsiftpDestinationUrl=${hosts[$index2]}
					if [[ "$gsiftpDestinationUrl" == "" ]]; then
						continue
					fi
					gsiftpSourceFqdn=$( echo "$gsiftpSourceUrl" | sed -e 's|^.*://||' -e 's/:.*$//' )
					gsiftpDestinationFqdn=$( echo "$gsiftpDestinationUrl" | sed -e 's|^.*://||' -e 's/:.*$//' )
					alias="${gsiftpSourceFqdn}--to--${gsiftpDestinationFqdn}"
					
					createDataPath "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$alias" "$dataPathsDir" "$dpathTemplate"

					returnValue="$?"

					if [[ "$returnValue" == "2" ]]; then
						echo "ERROR: Data path file already exists. For changes please edit \"$dataPathsDir/$alias\" directly!"
						exit 1
					elif [[ "$returnValue" != "0" ]]; then
						echo "ERROR: Problems during data path creation!"
						exit 1
					else
						echo "INFO: Data path \"$dataPathsDir/$alias\" was created."
					fi
				
				fi
			done
		done
		
		#  create index files

		exit "$returnValue"			
		
	fi

#  CREATE mode
elif [[ "$createDataPathSet" == "0" ]]; then
	if [[ "$gsiftpSourceUrlSet" != "0" || \
	      "$gsiftpDestinationUrlSet" != "0" || \
	      "$aliasSet" != "0" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit 1
	else
		if [[ "$dataPathsDir" == "" ]]; then
			dataPathsDir="$defaultDataPathsDir"
		fi

		createDataPath "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$alias" "$dataPathsDir"

		returnValue="$?"

		if [[ "$returnValue" == "2" ]]; then
			echo "ERROR: Data path file already exists. For changes please edit \"$dataPathsDir/$alias\" directly!"
			exit 1
		elif [[ "$returnValue" != "0" ]]; then
			echo "ERROR: Problems during data path creation!"
			exit 1
		else
			if [[ "$EDITOR" != "" ]]; then
				$EDITOR $dataPathsDir/$alias
				echo "INFO: Data path \"$dataPathsDir/$alias\" was created."
			else
				echo "INFO: Data path \"$dataPathsDir/$alias\" was created. Please use your preferred editor to edit the data path."
			fi
		fi

		exit "$?"
		
	fi

#  LIST mode
elif [[ "$listDataPathsSet" == "0" ]]; then

	if [[ "$dataPathsDir" == "" ]]; then
		#  list both system and user dpaths
		if [[ "$verboseExecSet" == "0" ]]; then
			echo "User dpaths ($defaultDataPathsDir):"
			listDataPaths -v "$defaultDataPathsDir"
			echo "System dpaths ($systemDataPathsDir):"			
			listDataPaths -v "$systemDataPathsDir"
		else
			echo "User dpaths:"
			listDataPaths "$defaultDataPathsDir"
			echo "System dpaths:"
			listDataPaths "$systemDataPathsDir"
		fi
	else
		if [[ "$verboseExecSet" == "0" ]]; then
			listDataPaths -v "$dataPathsDir"
		else
			listDataPaths "$dataPathsDir"
		fi	
	fi	

	exit $?

elif [[ "$listSourcesSet" == "0" ]]; then
	
	if [[ "$dataPathsDir" == "" ]]; then
		#  list all possible sources (from system and user dpaths) and
		#+ eliminate double entries.
		( listSources "$defaultDataPathsDir"
		  listSources "$systemDataPathsDir" ) | sort -u
	else
		listSources "$dataPathsDir"
	fi

	exit $?

elif [[ "$listDestinationsSet" == "0" ]]; then

	if [[ "$dataPathsDir" == "" ]]; then
		#  list all possible destinations (from system and user dpaths)
		#+ and eliminate double entries.
		( listDestinations "$defaultDataPathsDir"
		  listDestinations "$systemDataPathsDir" )  | sort -u
	else
		listDestinations "$dataPathsDir"
	fi

	exit $?

#  RETRIEVE mode
elif [[ "$retrieveDataPathsSet" == "0" ]]; then

	if ! use wget tar; then
		#echo "ERROR: Cannot run without required tools (wget, tar)! Exiting now!"
		exit 1
	fi

	if [[ "$dataPathsDir" == "" ]]; then
		dataPathsDir="$defaultDataPathsDir"
	fi

	if [[ "$quietExecSet" == "0" ]]; then
		retrieveDataPaths -q "$dataPathsDir"
		returnValue="$?"
	else
		retrieveDataPaths "$dataPathsDir"
		returnValue="$?"
	fi

	if [[ "$returnValue" != "0" && "$quietExecSet" == "0" ]]; then
		exit 1
	elif [[ "$returnValue" != "0" ]]; then
		echo "ERROR: Problems during dpaths retrieval!"
		exit 1
	else
		exit 0
	fi

else
	usageMsg
	exit 1

fi

