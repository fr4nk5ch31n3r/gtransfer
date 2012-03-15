#!/bin/bash

#  gtransfer - wrapper for tgftp with support for:
#+ * datapathing
#+ * default parameter usage
#+ * ...

:<<COPYRIGHT

Copyright (C) 2010, 2011 Frank Scheiner, HLRS, Universitaet Stuttgart
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

version="0.0.7d"
gsiftpUserParams=""

#  path to configuration file (prefer system paths!)
if [[ -e "/opt/gtransfer/etc/gtransfer.conf" ]]; then
	gtransferConfigurationFile="/opt/gtransfer/etc/gtransfer.conf"
elif [[ -e "/etc/opt/gtransfer/gtransfer.conf" ]]; then
	gtransferConfigurationFile="/etc/opt/gtransfer/gtransfer.conf"
elif [[ -e "$HOME/.gtransfer/gtransfer.conf" ]]; then
	gtransferConfigurationFile="$HOME/.gtransfer/gtransfer.conf"
fi

################################################################################
#  FUNCTIONS  ##################################################################
################################################################################

#USAGE##########################################################################
usageMsg()
{
        cat <<USAGE

usage: $(basename $0) [--help] ||
       $(basename $0) \\
        --source|-s gsiftpSourceUrl \\
        --destination|-d gsiftpDestinationUrl \\
        [optional params] \\
        [-- gsiftpParameters]

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

$(basename $0) \\
 --source|-s sourceUrl \\
 --destination|-d destinationUrl \\
 [--verbose|-v] \\
 [--metric|-m dataPathMetric] \\
 [--auto-clean|-a] \\
 [-- gsiftpParameters]

DESCRIPTION:

gtransfer is a wrapper script for tgftp that supports (GridFTP) transfers along
predefined paths by using transit sites. Additionally it supports usage of
default parameters for specific connections. Therefore this tool is also helpful
for direct transfers.

OPTIONS:

There's bash completion available for gtransfer. This supports completion of
options and URLs. URL completion also expands (remote) paths. Just hit the <TAB>
key to see what's possible.

The options are as follows:

--source|-s sourceUrl
                        Determine the source URL for the transfer.

			Possible URL examples:

			{[gsi]ftp|http}://FQDN[:PORT]/path/to/file
			[file://]/path/to/file

			"FQDN" is the fully qualified domain name.

--destination|-d destinationUrl
                        Determine the destination URL for the transfer.

			Possible URL examples:

			{[gsi]ftp}://FQDN[:PORT]/path/to/file
			[file://]/path/to/file

			"FQDN" is the fully qualified domain name.

[--verbose|-v]		Be verbose.

[--metric|-m dataPathMetric]
			Determine the metric to select the corresponding data
			path.

[--logfile|-l logfile]	Determine the name for the logfile, tgftp will generate
			for each transfer. If specified with ".log" as
			extension, gtransfer will insert a "__step_#" string to
			the name of the logfile ("#" is the number of the
			transfer step performed). If omitted gtransfer will
			automatically generate a name for the logfile(s).

[--auto-clean|-a]	Remove logfiles automatically after the transfer
			completed.

[--configfile configurationFile]
			Determine the name of the configuration file for
			gtransfer. If not set, this defaults to:

			"/opt/gtransfer/etc/gtransfer.conf" or

			"/etc/opt/gtransfer/gtransfer.conf" or

			"$HOME/.gtransfer/gtransfer.conf" in this order.

[-- gsiftpParameters]	Determine the "globus-url-copy" parameters that should
			be used for all transfer steps. Notice the space between
			"--" and the actual parameters. This overwrites any
			available default parameters and is not recommended for
			regular usage. There exists one exception for "-len" or
			"-partial-length". If one of these is provided, it will
			only be added to the default parameters for a connection
			or - if no default parameters are available - to the
			builtin default parameters.

			NOTICE:
			If specified, this option must be the last one in a
			gtransfer command line.

--------------------------------------------------------------------------------

[--help]                Prints out a help message.

[--version|-V]          Prints out version information.

HELP

	return
}
#END_HELP#######################################################################


#VERSION########################################################################
versionMsg()
{
	echo "gtransfer - The GridFTP transfer script v$version"

        return
}
#END_VERSION####################################################################


checkConnection()
{
	#  determines if a direct connection between the user's machine and the
	#+ target machine is possible
	#
	#  usage:
	#+ checkConnection "target"
	#
	#  NOTICE:
	#+ source has to be valid "protocol://fqdn:port" URL without path.

	#echo "DEBUG1: checkConnection $1"

	#  handle file URLs specially!
	if [[ $(echo "$1" | cut -d '/' -f "1-3") == "file://" ]]; then
		#  just return "0", so "guc" will handle missing files
		return 0
	fi	

	#                                      +-> strip protocol
	#                                      |
	#                                      |               +-> strip username portion
	#                                      |               |            
	#                                      |               |            +-> strip port
	#                                      |               |            |
	local targetHostname=$(echo "$1" | sed -e "s|^.*://||" -e "s/.*@//" -e "s/:.*$//")
	local targetPort=$(echo "$1" | sed -e "s/^.*://")

	#  check target
	if ! scanPort "$targetHostname" "$targetPort"; then
		#  port closed/blocked/etc.
		return 1
	else
		#  port open
		return 0
	fi
}

kill_after_timeout()
{
        local KPID="$1"

        local TIMEOUT="$2"

        #  if $TIMEOUT is "0" just return and don't kill the process
        if [[ "$TIMEOUT" == "0" ]]; then
                return
        fi

        sleep "$TIMEOUT"

        if ps -p "$KPID" &>/dev/null ; then
                kill "$KPID" &>/dev/null

                #  indicate that the pid was killed
                touch .GSIFTP_COMMAND_KILLED
                RETURN_VAL="0"
        else
                RETURN_VAL="1"
        fi

        return
}

scanPort()
{
	#  determines if a port is open at a remote site, or not
	#
	#  usage:
	#+ scanPort "targetSiteHostname" "targetPort"

	local targetSiteHostname="$1"
	local targetPort="$2"

	echo "open $targetSiteHostname $targetPort" | telnet 2>/dev/null 1> .scanResult &

	scanCommandPid="$!"

	kill_after_timeout "$scanCommandPid" "2" &

	wait $scanCommandPid &>/dev/null

	if cat ".scanResult" | grep "Connected" &>/dev/null; then
		rm ".scanResult"
		return 0
	else
		rm ".scanResult"
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
		if ! which $tool &>/dev/null; then
			requiredToolNotAvailable=0
			echo "ERROR: Required tool \"$tool\" not available!"
		fi
	done

	if [[ $requiredToolNotAvailable == 0 ]]; then
		echo "       Cannot run without required tools! Exiting now!"
		exit 1
	fi
}

isValidUrl()
{
	#  determines if a valid URL was used
	#
	#  usage:
	#+ isValidUrl url

	local url="$1"

	#  if the URL starts with an absolute path it's equal to "file://$URL"
	#+ and therefore valid.
	if  [[ ${url:0:1} == "/" ]]; then
		return 0
	#  protocol specifier missing?
	elif ! echo $url | grep ".*://" &>/dev/null; then
		#echo "ERROR: Protocol specifier missing in \"$URL\" and no local path specified!"
		return 1
	fi
}

getProtocolSpecifier()
{
	#  determine the protocol specifier for a URL
	#
	#  usage:
	#+ getProtocolSpecifier url

	local url="$1"

	local protocolSpecifier=""

	#  if the URL starts with an absolute path it's equal to "file://$URL"
	if  [[ ${url:0:1} == "/" ]]; then
		echo "file://"
		return 0
	#  return the protocol specifier
	else
		protocolSpecifier=$( echo $url | grep -o ".*://" )
		echo "$protocolSpecifier"
		return 0
	fi
}

getURLWithoutPath()
{
	#  determines the URL portion that consists of the protocol id, the
	#+ domain name and the port, or "file://":
	#
	#  (gsiftp://venus.milkyway.universe:2811)/path/to/file
	#  (file://)/path/to/local/file
	#
	#  usage:
	#+ getURLWithoutPath "URL"

	local URL="$1"
	
	#  TODO:
	#+ support URLs not containing any port descriptions:
	#
	#  done!
	
	:<<-COMMENT
	from: <http://wiki.linuxquestions.org/wiki/Regular_expression>
	"
	echo gsiftp://venus.milkyway.universe/path/to/file | sed "s;\(gsiftp://[^/]*\)/.*;\1;"
	"

	or

	"
	echo gsiftp://venus.milkyway.universe/path/to/file | cut -d '/' -f "1-3"
	"

	returns:
	"
	gsiftp://venus.milkyway.universe
	"
	COMMENT

	#local tmp=$(echo "$URL" | grep -o "gsiftp://.*:[[:digit:]]*")
	local tmp=""
	#  URL starting with "/", then this is a local path (equal to
	#+  "file://$URL".
	if [[ ${URL:0:1} == "/" ]]; then
		#echo "DEBUG: 1"
		tmp="file://"
	#  valid URL
	else
		#echo "DEBUG: 3"
		tmp=$( echo $URL | cut -d '/' -f "1-3" )
	fi

	#if [[ "$tmp" == "" ]]; then
	#	tmp=$( echo "$URL" | grep -o "file://" )
	#fi

	#  Add default port automatically (if missing!)
	#  does $tmp start with 'gsiftp://'?
	if echo $tmp | grep '^gsiftp://' &>/dev/null; then
		#  if yes, check if port is provided
		if echo $tmp | grep -o ':[[:digit:]].*' &>/dev/null; then
			#  port provided by user, don't modify string
			:
		else
			#  no port provided, add default gsiftp port
			tmp="${tmp}:2811"
		fi
	#  does $tmp start with 'ftp://'?
	elif echo $tmp | grep '^ftp://' &>/dev/null; then
		#  if yes, check if port is provided
		if echo $tmp | grep -o ':[[:digit:]].*' &>/dev/null; then
			#  port provided by user, don't modify string
			:
		else
			#  no port provided, add default ftp port
			tmp="${tmp}:21"
		fi
	#  does $tmp start with 'http://'?
	elif echo $tmp | grep '^http://' &>/dev/null; then
		#  if yes, check if port is provided
		if echo $tmp | grep -o ':[[:digit:]].*' &>/dev/null; then
			#  port provided by user, don't modify string
			:
		else
			#  no port provided, add default ftp port
			tmp="${tmp}:80"
		fi
	#  does $tmp start with 'https://'?
	elif echo $tmp | grep '^https://' &>/dev/null; then
		#  if yes, check if port is provided
		if echo $tmp | grep -o ':[[:digit:]].*' &>/dev/null; then
			#  port provided by user, don't modify string
			:
		else
			#  no port provided, add default ftp port
			tmp="${tmp}:443"
		fi
	fi

	local URLWithoutPath=$tmp

	echo "$URLWithoutPath"
}

getPathFromURL()
{
	#  determines the path portion from the URL:
	#
	#  gsiftp://venus.milkyway.universe:2811(/path/to/)file
	#
	#  usage:
	#+ getPathFromURL "URL"

	local URL="$1"

	#  local path?
	if echo $URL | grep "^.*://" &>/dev/null; then
                #  no
                #  gsiftp://venus.milkyway.universe:2811/path/to/file
		#  gsiftp://venus.milkyway.universe:2811/file
		#  strip protocol spec, domain name and port
		#  path/to/file
		#  file
		local tmp=$( echo "$URL" | cut -d '/' -f '4-' )

		#  add leading '/'
		#  /path/to/file
		#  /file
		tmp="/$tmp"

		#  strip file portion from it
                #  /path/to
		#  ""
		tmp=${tmp%\/*}

                #  add slashes if needed
                if [[ "$tmp" == "" ]]; then
                        #  /
                        tmp="/"
                else
                        #  /path/to/
                        tmp="$tmp/"
                fi
	else
       		#  yes
                #  /path/to/file
                #  not allowed: file !
		
                #  so strip only the file portion from it
                tmp=${URL%\/*}

                #  add slashes if needed
                if [[ "$tmp" == "" ]]; then
                        #  /
                        tmp="/"
                else
                        #  /path/to/
                        tmp="$tmp/"
                fi
	fi

	path="$tmp"	

	echo "$path"

        return
}

getFilenameFromURL()
{
	#  determines the file portion (if any) from the URL:
	#
	#  gsiftp://venus.milkyway.universe:2811/path/to/(file)
	#
	#  usage:
	#+ getFilenameFromURL "URL"
	
	local URL="$1"

	#local tmp=$(echo "$URL" | sed -e "s|$( getURLWithoutPath $URL )||")
	local tmp=$( echo "$URL" | sed -e "s/^.*\///" )
	#local tmp=$( echo "$URL" | cut -d '/' -f '4-' )

	#  strip any path portion from file
	#file=$(basename $file)
	#  doesn't work "correctly" =>
	#+ "/lrztemp/test1/*/file/" is evaluated to "file" but should be empty
	#file=$(echo $file | sed -e "s|^.*/||")
	file=${tmp##*/}

	#  file may contain "*" which would be expanded by the shell, therefore
	#+ this clause decides if the function echoes a "*" or "$file".
	if [[ "$file" == "*" ]]; then	
		echo '*'
	else
		echo "$file"
	fi
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

hashSourceDestination()
{
	#  hashes the "source;destination" combination
	#
	#  usage:
	#+ hashSourceDestination source destination
	#
	#  NOTICE:
	#+ "source" and "destination" are URLs without path but !

	local sourceWithoutPath="$1"
	local destinationWithoutPath="$2"

	local dataPathName=$(echo "$sourceWithoutPath;$destinationWithoutPath" | sha1sum | cut -d ' ' -f 1)

	echo $dataPathName
}

echoIfVerbose()
{
	if [[ $verboseExec == 0 ]]; then
		echo $@
	fi

	return		
}

echoDebug()
{
	local fd="$1"
	local debugLevel="$2"
	local debugString="$3"

	if [[ "$fd" == "stdout" ]]; then
		echo "$debugLevel: $debugString"
	elif [[ "$fd" == "stderr" ]]; then
		echo "$debugLevel: $debugString" 1>&2
	else
		echo "$debugLevel: $debugString" >$fd
	fi		

	return
}

createTgftpTransferCommand()
{
	#  creates the tgftp transfer command and puts it in a file
	#
	#  usage:
	#+ createTgftpTransferCommand source \
	#+                            destination \
	#+                            gsiftpParams \
	#+                            tgftpTransferCommand \
	#+                            logfileName \
	#+                            transitSite

	local source="$1"
	local destination="$2"
	local gsiftpParams="$3"
	local tgftpTransferCommand="$4"
	local logfileName="$5"
	local transitSite="$6"

	local tgftpPostCommandParam=""
	local tgftpPostCommand=""

	#  If a transit site is involved as source, the temporary transit
	#+ directory will be removed after the transfer succeeded.
	if [[ $transitSite -eq 0 ]]; then
		#tgftpPostCommandParam="--post-command"
		#  remove the whole temp. transit dir from the transit site
		#tgftpPostCommand="uberftp -rm -r $( getURLWithoutPath $source )$( getPathFromURL $source ) &"
		:
	fi

	#echo "$@"

	#echo "tgftpTransferCommand: $tgftpTransferCommand $4"

	if [[ $verboseExec -eq 0 && $transitSite -eq 1 ]]; then
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "-- \"$gsiftpParams\"" | tee "$tgftpTransferCommand"
	elif [[ $verboseExec -eq 0 && $transitSite -eq 0 ]]; then
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
		     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\"" | tee "$tgftpTransferCommand"
	elif [[ $verboseExec -eq 1 && $transitSite -eq 0 ]]; then
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
		     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\"" > "$tgftpTransferCommand"
	else
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "-- \"$gsiftpParams\"" > "$tgftpTransferCommand"
	fi

	if [[ $? -eq 0 ]]; then
		return 0
	else
		return 1
	fi
}


simulateTransfer()
{
	#  creates a specific tgftpTransferCommand that only blocks for 10 secs
	#+ and then exits.
	#
	#  usage:
	#+ simulateTransfer

	echo "sleep 10" > $tgftpTransferCommand
}

simulateError()
{
	#  creates a specific tgftpTransferCommand that only blocks for 10 secs
	#+ and then exits with "1", indicating an error.
	#
	#  usage:
	#+ simulateError

	echo "sleep 10;exit 1" > $tgftpTransferCommand
}

transferData()
{
	#  transfers data from source to destination
	#
	#  usage:
	#+ transferData source destination metric tmpLogfileName

	#  TODO:
	#
	#  If a source URL ends with "/" or "/*", the destination URL has to end
	#+ with "/". Make sure this is the case!

	local source="$1"
	local destination="$2"
	local dataPathMetric="$3"
	local tgftpTempLogfileName="$4"
	local tgftpLogfileName=""

	#  Check if valid URLs are provided
	if ! isValidUrl $source; then
		echo "ERROR: Protocol specifier missing in \"$source\" and no local path specified!"
		exit 1
	elif ! isValidUrl $destination; then
		echo "ERROR: Protocol specifier missing in \"$destination\" and no local path specified!"
		exit 1
	#  check if destination URL is a "http://" URL
	elif [[ "$( getProtocolSpecifier $destination )" == "http://" || \
	        "$( getProtocolSpecifier $destination )" == "https://" \
	]]; then
		echo "ERROR: Destination URL cannot be a \"http[s]://\" URL!"
		exit 1
	fi

	local sourceWithoutPath=$(getURLWithoutPath "$source")
	local destinationWithoutPath=$(getURLWithoutPath "$destination")

	local sourceUsernamePortion=$( echo $sourceWithoutPath | grep -o "://.*@" | sed -e 's/:\/\///' )
	local destinationUsernamePortion=$( echo $destinationWithoutPath | grep -o "://.*@" | sed -e 's/:\/\///' )

	local sourcePath=$(getPathFromURL "$source")
	local destinationPath=$(getPathFromURL "$destination")

	local sourceFile=$(getFilenameFromURL "$source")
	local destinationFile=$(getFilenameFromURL "$destination")

	local memToMem=1

	#  is this a memory to memory transfer?
	if [[ "${sourcePath}${sourceFile}" == "/dev/zero" && \
	      "${destinationPath}${destinationFile}" == "/dev/null" \
	]]; then
		memToMem=0
	fi

	#  get corresponding data path (and remove any "username@" portions in
	#+ the URL before hashing).
	local dataPathFilename="$(hashSourceDestination $( echo $sourceWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) $( echo $destinationWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) )"

	if [[ -e "$gtransferDataPathDirectory/$dataPathFilename" ]]; then
		local dataPathFile="$gtransferDataPathDirectory/$dataPathFilename"
	elif [[ -e "$gtransferSystemDataPathDirectory/$dataPathFilename" ]]; then
		local dataPathFile="$gtransferSystemDataPathDirectory/$dataPathFilename"
	fi

	#  source and destination for transfer step
	local transferStepSource=""
	local transferStepDestination=""

	local transferStepSourceWithoutPath=""
	local transferStepDestinationWithoutPath=""

	#  temporary dir on transit site
	#
	#  NOTICE:
	#+ This contains no leading/trailing "/"!
	local transitSiteTempDir=$( mktemp -u "transitSiteTempDir.XXXXXXXX" )

	#  default params file and default params
	local transferStepDefaultParamsFile=""
	local transferStepDefaultParams=""

	#  data path file existing?
	if [[ -e "$dataPathFile" && \
	      $memToMem != 0 \
	]]; then
		#  yes, initiate transfers along the path

		echoIfVerbose -e "Data path used:\n$dataPathFile"

		COUNTER=0

		#echoDebug "stdout" "DEBUG1" "before xtract"

		#xtractXMLAttributeValue "path metric=\"$dataPathMetric\"" $dataPathFile

		for transferStep in $(xtractXMLAttributeValue "path metric=\"$dataPathMetric\"" $dataPathFile); do

			#echoDebug "stdout" "DEBUG1" "in for loop"

			#  get source and destination for transfer step
			#+ source is in the left column, destination in the right column

			echoIfVerbose "Transfer step: $COUNTER"

			transferStepSource=${transferStep%%;*}
			transferStepDestination=${transferStep##*;}

			transferStepSourceWithoutPath=$(getURLWithoutPath "$transferStepSource")
			transferStepDestinationWithoutPath=$(getURLWithoutPath "$transferStepDestination")

			#  check if connection to source and destination is possible
			#  TODO:
			#+ Change function name to e.g. connectionPossible.
			if ! checkConnection "$transferStepSourceWithoutPath"; then
				echo "ERROR: Cannot connect to \"$transferStepSourceWithoutPath\"!"
				exit 1
			elif ! checkConnection "$transferStepDestinationWithoutPath"; then
				echo "ERROR: Cannot connect to \"$transferStepDestinationWithoutPath\"!"
				exit 1
			fi

			#  (0) construct logfilename
			tgftpLogfileName="${tgftpTempLogfileName/%.log/__step_${COUNTER}.log}"

			#  get default params for the transfer step
			#+ (1) get filename for default params (and remove any
			#+ "username@" portions in the URL before hashing).
			local transferStepDefaultParamsFilename="$(hashSourceDestination $( echo $transferStepSourceWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) $( echo $transferStepDestinationWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) )"

			#  if existing prefer user's dparam
			if [[ -e "$gtransferDefaultParamsDirectory/$transferStepDefaultParamsFilename" ]]; then
				local transferStepDefaultParamsFile="$gtransferDefaultParamsDirectory/$transferStepDefaultParamsFilename"
			#  if no user's dparam exists, try the system's one instead
			elif [[ -e "$gtransferSystemDefaultParamsDirectory/$transferStepDefaultParamsFilename" ]]; then
				local transferStepDefaultParamsFile="$gtransferSystemDefaultParamsDirectory/$transferStepDefaultParamsFilename"
			#  if dparam does not exist, the $transferStepDefaultParamsFile variable must be set anyhow.
			else
				local transferStepDefaultParamsFile="$gtransferDefaultParamsDirectory/$transferStepDefaultParamsFilename"
			fi

			#  (2) get default params
			if [[ -e "$transferStepDefaultParamsFile" && \
			      -z "$gsiftpUserParams" \
			]]; then
				#  default params file available, no user params
				#+ specified
				transferStepDefaultParams="$(xtractXMLAttributeValue "gsiftp_params" $transferStepDefaultParamsFile)"
				echoIfVerbose -e "Default params used:\n$transferStepDefaultParamsFile"

			elif [[ -e "$transferStepDefaultParamsFile" && \
			        -n "$gsiftpUserParams" \
			]]; then
				transferStepDefaultParams="$(xtractXMLAttributeValue "gsiftp_params" $transferStepDefaultParamsFile)"

				grepMatch=$( echo "$gsiftpUserParams" | egrep -o "\-len [[:alnum:]]*|\-partial-length [[:alnum:]]*" )
				if [[ "$grepMatch" == "$gsiftpUserParams" ]]; then
					transferStepDefaultParams="$transferStepDefaultParams $gsiftpUserParams"
				else
					transferStepDefaultParams="$gsiftpUserParams"
				fi

				#echoIfVerbose -e "Default params used:\n$transferStepDefaultParamsFile"
			
			elif [[ -n "$gsiftpUserParams" ]]; then
				#  no default params available, use parameters
				#+ supplied by user or a combination of builtin
				#+ parameters and "-len"
				grepMatch=$( echo "$gsiftpUserParams" | egrep -o "\-len [[:alnum:]]*|\-partial-length [[:alnum:]]*" )
				if [[ "$grepMatch" == "$gsiftpUserParams" ]]; then
					transferStepDefaultParams="$gsiftpDefaultParams $gsiftpUserParams"
				else
					transferStepDefaultParams="$gsiftpUserParams"
				fi

			else
				#  no default params available, use builtin
				#+ default parameters
				transferStepDefaultParams="$gsiftpDefaultParams"
			fi

			#  Add given usernames to source and final destination
			#+ URLs
			#sourceUsernamePortion
			#destinationUsernamePortion
			
			#  (3) transfer data (various steps possible!)
			
			#  TODO:
			#
			#  There's also a fourth possible step, where source and
			#+ destination URLs don't have a path (direct connection
			#+ possible).
			#
			#  DONE:
			#+ implementation:
			if [[ "$transferStepSource" == "$(getURLWithoutPath $transferStepSource)" && \
		      	      "$transferStepDestination" == "$(getURLWithoutPath $transferStepDestination)" \
			]]; then

				#  handle usernames in URLs
				transferStepSourceProtoSpec=$( getProtocolSpecifier $transferStepSource )
				transferStepDestinationProtoSpec=$( getProtocolSpecifier $transferStepDestination )
				#  replace protocol spec with proto. spec and username (don't forget "@" at the end)
				#  NOTICE:
				#+ Please be aware of the fact, that the shell expands the variables in the sed scripts before actually running the sed scripts.
				#+ As the proto. spec contains "/"es. they must be either escaped (hard!) or one just changes the "/"es of the "s///" command to
				#+ "|"s.
				transferStepSource=$( echo $transferStepSource | sed -e "s|${transferStepSourceProtoSpec}|${transferStepSourceProtoSpec}${sourceUsernamePortion}|" )
				transferStepDestination=$( echo $transferStepDestination | sed -e "s|${transferStepDestinationProtoSpec}|${transferStepDestinationProtoSpec}${destinationUsernamePortion}|" )

				createTgftpTransferCommand \
                                 "${transferStepSource}${sourcePath}${sourceFile}" \
                                 "${transferStepDestination}${destinationPath}${destinationFile}" \
                                 "$transferStepDefaultParams" \
                                 "$tgftpTransferCommand" \
				 "$tgftpLogfileName" \
				 "1"

				#simulateTransfer

				if [[ $? != 0 ]]; then
					echo "ERROR: tgftp transfer command couldn't be created!"
					exit 1
				fi

				bash $tgftpTransferCommand &>"${tgftpTransferCommand}Output" &
				
			#  initial transfer step
			#
			#  The initial transfer step can be detected as follows:
			#+ The source portion has no path added to the URL.
			elif [[ "$transferStepSource" == "$(getURLWithoutPath $transferStepSource)" ]]; then

				#  handle usernames in URLs
				transferStepSourceProtoSpec=$( getProtocolSpecifier $transferStepSource )
				#  replace protocol spec with proto. spec and username (don't forget "@" at the end)
				#  NOTICE:
				#+ Please be aware of the fact, that the shell expands the variables in the sed scripts before actually running the sed scripts.
				#+ As the proto. spec contains "/"es. they must be either escaped (hard!) or one just changes the "/"es of the "s///" command to
				#+ "|"s.
				transferStepSource=$( echo $transferStepSource | sed -e "s|${transferStepSourceProtoSpec}|${transferStepSourceProtoSpec}${sourceUsernamePortion}|" )

				createTgftpTransferCommand \
                                 "${transferStepSource}${sourcePath}${sourceFile}" \
                                 "${transferStepDestination}${transitSiteTempDir}/" \
                                 "$transferStepDefaultParams" \
                                 "$tgftpTransferCommand" \
				 "$tgftpLogfileName" \
				 "1"

				#simulateTransfer
				#simulateError

				if [[ $? != 0 ]]; then
					echo "ERROR: tgftp transfer command couldn't be created!"
					exit 1
				fi

				bash $tgftpTransferCommand &>"${tgftpTransferCommand}Output" &

			#  transfer from transit site to transit site
			#
			#  A transfer from transit site to transit site can be
			#+ detected as follows:
			#+ A transit address has a temp path added to the URL
			#+ and therefore should differ from the string printed
			#+ by getURLWithoutPath().
			elif [[ "$transferStepDestination" != "$(getURLWithoutPath $transferStepDestination)" ]]; then

				createTgftpTransferCommand \
                                 "${transferStepSource}${transitSiteTempDir}/${sourceFile}" \
                                 "${transferStepDestination}${transitSiteTempDir}/" \
                                 "$transferStepDefaultParams" \
                                 "$tgftpTransferCommand" \
				 "$tgftpLogfileName" \
				 "0"

				#simulateTransfer

				bash $tgftpTransferCommand &>${tgftpTransferCommand}Output &

			#  last step
			#
			#  The last step is identified by the transfer step
			#+ destination being identical to the destination of the
			#+ data path, which itself is identical to the
			#+ destination without path portion.
			elif [[ "$transferStepDestination" == "$(getURLWithoutPath $transferStepDestination)" ]]; then

				#  handle usernames in URLs
				transferStepDestinationProtoSpec=$( getProtocolSpecifier $transferStepDestination )
				#  replace protocol spec with proto. spec and username (don't forget "@" at the end)
				#  NOTICE:
				#+ Please be aware of the fact, that the shell expands the variables in the sed scripts before actually running the sed scripts.
				#+ As the proto. spec contains "/"es. they must be either escaped (hard!) or one just changes the "/"es of the "s///" command to
				#+ "|"s.
				transferStepDestination=$( echo $transferStepDestination | sed -e "s|${transferStepDestinationProtoSpec}|${transferStepDestinationProtoSpec}${destinationUsernamePortion}|" )

				createTgftpTransferCommand \
                                 "${transferStepSource}${transitSiteTempDir}/${sourceFile}" \
                                 "${transferStepDestination}${destinationPath}${destinationFile}" \
                                 "$transferStepDefaultParams" \
                                 "$tgftpTransferCommand" \
				 "$tgftpLogfileName" \
				 "0"

				#simulateTransfer
				#simulateError

				if [[ $? != 0 ]]; then
					echo "ERROR: tgftp transfer command couldn't be created!"
					exit 1
				fi

				bash $tgftpTransferCommand &>${tgftpTransferCommand}Output &

			fi

			tgftpTransferCommandPid="$!"

			#  indicate progress
			while ps -p$tgftpTransferCommandPid &>/dev/null; do
				echo -n "."
				sleep 2
			done

			echoIfVerbose ""

			wait $tgftpTransferCommandPid

			#  did the current transfer step work?
			if [[ $? != 0 ]]; then
				#  no
				cat ${tgftpTransferCommand}Output
				echo ""
				echo "ERROR: Transfer step #$COUNTER failed!" #\
                                     #"Please see \"${tgftpTransferCommand}Output\" for details!"
				exit 1
			else
				#  yes
				rm -f "${tgftpTransferCommand}*" &>/dev/null
			fi

			COUNTER=$(( $COUNTER +1 ))
		done
	
	else
		#  no data path file available for this transfer, try direct transfer
		#  get source and destination for transfer step
		transferStepSource=$source
		transferStepDestination=$destination

		transferStepSourceWithoutPath=$(getURLWithoutPath "$transferStepSource")
		transferStepDestinationWithoutPath=$(getURLWithoutPath "$transferStepDestination")

		#  check if connection to source and destination is possible
		if ! checkConnection "$transferStepSourceWithoutPath"; then
			echo "ERROR: Cannot connect to \"$transferStepSourceWithoutPath\"!"
			exit 1
		elif ! checkConnection "$transferStepDestinationWithoutPath"; then
			echo "ERROR: Cannot connect to \"$transferStepDestinationWithoutPath\"!"
			exit 1
		fi

		#  (0) construct logfilename
		tgftpLogfileName="$tgftpTempLogfileName"

		#  get default params for the transfer
		#+ (1) get filename for default params (and remove any
		#+ "username@" portions in the URL before hashing).
		local transferStepDefaultParamsFilename="$(hashSourceDestination $( echo $transferStepSourceWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) $( echo $transferStepDestinationWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) )"

		if [[ -e "$gtransferDefaultParamsDirectory/$transferStepDefaultParamsFilename" ]]; then
			local transferStepDefaultParamsFile="$gtransferDefaultParamsDirectory/$transferStepDefaultParamsFilename"
		elif [[ -e "$gtransferSystemDefaultParamsDirectory/$transferStepDefaultParamsFilename" ]]; then
			local transferStepDefaultParamsFile="$gtransferSystemDefaultParamsDirectory/$transferStepDefaultParamsFilename"
		fi

		#  (2) get default params
		if [[ -e "$transferStepDefaultParamsFile" && \
		      -z "$gsiftpUserParams" \
		]]; then
			transferStepDefaultParams="$(xtractXMLAttributeValue "gsiftp_params" $transferStepDefaultParamsFile)"
			echoIfVerbose -e "Default params used:\n$transferStepDefaultParamsFile"

		elif [[ -e "$transferStepDefaultParamsFile" && \
		        -n "$gsiftpUserParams" \
		]]; then
			transferStepDefaultParams="$(xtractXMLAttributeValue "gsiftp_params" $transferStepDefaultParamsFile)"

			grepMatch=$( echo "$gsiftpUserParams" | egrep -o "\-len [[:alnum:]]*|\-partial-length [[:alnum:]]*" )

			if [[ "$grepMatch" == "$gsiftpUserParams" ]]; then
				transferStepDefaultParams="$transferStepDefaultParams $gsiftpUserParams"
			else
				transferStepDefaultParams="$gsiftpUserParams"
			fi

			#echoIfVerbose -e "Default params used:\n$transferStepDefaultParamsFile"
			
		elif [[ -n "$gsiftpUserParams" ]]; then
			#  no default params available, use parameters
			#+ supplied by user or a combination of builtin 
			#+ parameters and "-len"
			grepMatch=$( echo "$gsiftpUserParams" | egrep -o "\-len [[:alnum:]]*|\-partial-length [[:alnum:]]*" )
			if [[ "$grepMatch" == "$gsiftpUserParams" ]]; then
				transferStepDefaultParams="$gsiftpDefaultParams $gsiftpUserParams"
			else
				transferStepDefaultParams="$gsiftpUserParams"
			fi

		else
			#  no default params available, use builtin
			#+ default parameters
			transferStepDefaultParams="$gsiftpDefaultParams"
		fi

		#  handle usernames in URLs
		transferStepSourceProtoSpec=$( getProtocolSpecifier $transferStepSource )
		transferStepDestinationProtoSpec=$( getProtocolSpecifier $transferStepDestination )
		#  replace protocol spec with proto. spec and username (don't forget "@" at the end)
		#  NOTICE:
		#+ Please be aware of the fact, that the shell expands the variables in the sed scripts before actually running the sed scripts.
		#+ As the proto. spec contains "/"es. they must be either escaped (hard!) or one just changes the "/"es of the "s///" command to
		#+ "|"s.
		transferStepSource=$( echo $transferStepSource | sed -e "s|${transferStepSourceProtoSpec}|${transferStepSourceProtoSpec}${sourceUsernamePortion}|" )
		transferStepDestination=$( echo $transferStepDestination | sed -e "s|${transferStepDestinationProtoSpec}|${transferStepDestinationProtoSpec}${destinationUsernamePortion}|" )

		createTgftpTransferCommand \
                 "$transferStepSourceWithoutPath${sourcePath}${sourceFile}" \
                 "$transferStepDestinationWithoutPath${destinationPath}${destinationFile}" \
                 "$transferStepDefaultParams" \
                 "$tgftpTransferCommand" \
		 "$tgftpLogfileName" \
		 "1"

		#simulateTransfer

		bash $tgftpTransferCommand &>${tgftpTransferCommand}Output &

		tgftpTransferCommandPid="$!"

		#  indicate progress
		while ps -p$tgftpTransferCommandPid &>/dev/null; do
			echo -n "."
			sleep 2
		done

		echoIfVerbose ""

		wait $tgftpTransferCommandPid

		#  did the current transfer step work?
		if [[ $? != 0 ]]; then
			#  no
			cat ${tgftpTransferCommand}Output
			echo ""
			echo "ERROR: The transfer failed!" #\
                             #"Please see \"${tgftpTransferCommand}Output\" for details!"
			exit 1
		else
			#  yes
			rm -f "${tgftpTransferCommand}*" &>/dev/null
		fi

	fi

	if [[ $verboseExec == 0 ]]; then
		echoIfVerbose -e "INFO: The transfer succeeded!"
	else
		echo ""
	fi

}

#  For testing internal functions:
#function="$1"
#shift 1
#$function $@
#
#exit 1

#MAIN###########################################################################

#  check that all required tools are available
use cat grep sed cut sleep tgftp telnet #uberftp

dataPathMetricSet="1"
tgftpLogfileNameSet="1"

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
		"$1" != "--source" && "$1" != "-s" && \
		"$1" != "--destination" && "$1" != "-d" && \
		"$1" != "--metric" && "$1" != "-m" && \
		"$1" != "--verbose" && "$1" != "-v" && \
		"$1" != "--auto-clean" && "$1" != "-a" && \
		"$1" != "--logfile" && "$1" != "-l" && \
		"$1" != "--configfile" && \
		"$1" != "--" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit 1   
	fi

	#  "--"
	if [[ "$1" == "--" ]]; then
		#  remove "--" from "$@"
		shift 1
		#  params forwarded to "globus-url-copy"
		gsiftpUserParams="$@"

		#  exit the loop (this assumes that everything left in "$@" is
		#+ a "globus-url-copy" param).		
		break

	#  "--help"
	elif [[ "$1" == "--help" ]]; then
		helpMsg
		exit 0

	#  "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then
		versionMsg
		exit 0

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

	#  "--metric|-m dataPathMetric"
	elif [[ "$1" == "--metric" || "$1" == "-m" ]]; then
		if [[ "$dataPathMetricSet" != "0" ]]; then
			shift 1
			dataPathMetric="$1"
			dataPathMetricSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--metric|-m\" cannot be used multiple times!"
			exit 1
		fi

	#  "--verbose|-v"
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
		if [[ $verboseExecSet != 0 ]]; then
			shift 1
			verboseExecSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--verbose|-v\" cannot be used multiple times!"
			exit 1
		fi

	#  "--auto-clean|-a"
	elif [[ "$1" == "--auto-clean" || "$1" == "-a" ]]; then
		if [[ $autoCleanSet != 0 ]]; then
			shift 1
			autoClean=0
			autoCleanSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--auto-clean|-a\" cannot be used multiple times!"
			exit 1
		fi

	#  "--logfile|-l"
	elif [[ "$1" == "--logfile" || "$1" == "-l" ]]; then
		if [[ $tgftpLogfileNameSet != 0 ]]; then
			shift 1
			tgftpLogfileName="$1"
			tgftpLogfileNameSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--logfile|-l\" cannot be used multiple times!"
			exit 1
		fi

	#  "--configfile"
	elif [[ "$1" == "--configfile" ]]; then
		if [[ $gtransferConfigurationFileSet != 0 ]]; then
			shift 1
			gtransferConfigurationFile="$1"
			gtransferConfigurationFileSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--configfile\" cannot be used multiple times!"
			exit 1
		fi

	fi

done

#  load configuration file
if [[ -e "$gtransferConfigurationFile" ]]; then
	. "$gtransferConfigurationFile"
else
	echo "ERROR: gtransfer configuration file missing!"
	exit 1
fi

#  verbose execution needed due to options?
if [[ $verboseExecSet == 0 ]]; then
	verboseExec=0
fi

#  all mandatory params present?
if [[ "$gsiftpSourceUrl" == "" || \
      "$gsiftpDestinationUrl" == "" \
]]; then
        #  no, so output a usage message
        usage_msg
        exit 1
fi

#  set dpath metric
if [[ "$dataPathMetricSet" != "0" ]]; then
	dataPathMetric="$defaultDataPathMetric"
fi

#  set logfile name
if [[ "$tgftpLogfileNameSet" != "0" ]]; then
	tgftpLogfileName="$defaultTgftpLogfileName"
fi

transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
transferDataReturnValue="$?"

#  automatically remove logfiles if needed
if [[ $autoClean == 0 ]]; then
	rm -rf ${tgftpLogfileName/%.log/}*
fi

exit $transferDataReturnValue

