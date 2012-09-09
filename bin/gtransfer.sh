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

#  prevent "*" expansion (filename globbing)
set -f

version="0.0.7c-dev06"
gsiftpUserParams=""

#  path to configuration file (prefer system paths!)
if [[ -e "/opt/gtransfer/etc/gtransfer.conf" ]]; then
        gtransferConfigurationFile="/opt/gtransfer/etc/gtransfer.conf"
#sed#elif [[ -e "<PATH_TO_GTRANSFER>/etc/gtransfer.conf" ]]; then
#sed#    gtransferConfigurationFile="<PATH_TO_GTRANSFER>/etc/gtransfer.conf"
elif [[ -e "/etc/opt/gtransfer/gtransfer.conf" ]]; then
        gtransferConfigurationFile="/etc/opt/gtransfer/gtransfer.conf"
elif [[ -e "$HOME/.gtransfer/gtransfer.conf" ]]; then
        gtransferConfigurationFile="$HOME/.gtransfer/gtransfer.conf"
fi

_GTRANSFER_LOCATION="$( dirname $gtransferConfigurationFile )"
chunkConfig="$_GTRANSFER_LOCATION/chunkConfig"
_LIB="$_GTRANSFER_LOCATION/lib"

################################################################################
#  INCLUDE LIBRARY FUNCTIONS
################################################################################

. "$_LIB"/exitCodes.bashlib
. "$_LIB"/listTransfer.bashlib
. "$_LIB"/autoOptimization.bashlib

################################################################################


################################################################################
#  FUNCTIONS
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

[--source|-s sourceUrl] Determine the source URL for the transfer.

                        Possible URL examples:

                        {[gsi]ftp|http}://FQDN[:PORT]/path/to/file
                        [file://]/path/to/file

                        "FQDN" is the fully qualified domain name.

[--destination|-d destinationUrl]
                        Determine the destination URL for the transfer.

                        Possible URL examples:

                        {[gsi]ftp}://FQDN[:PORT]/path/to/file
                        [file://]/path/to/file

                        "FQDN" is the fully qualified domain name.

[--transfer-list transferList]
                        As alternative to providing source and destination URLs
                        on the commandline one can also provide a list of source
                        and destination URLs. See the gt manual page for more
                        details.
                        
[--auto-optimize|-o transferMode]
			Activates automatic optimization of transfers
			depending on the size of files. The transferMode
			controls how files of different size classes are
			transferred. Currently only "seq[uential]" is possible.

[--verbose|-v]          Be verbose.

[--metric|-m dataPathMetric]
                        Determine the metric to select the corresponding data
                        path.

[--logfile|-l logfile]	Determine the name for the logfile, tgftp will generate
                        for each transfer. If specified with ".log" as
                        extension, gtransfer will insert a "__step_#" string to
                        the name of the logfile ("#" is the number of the
                        transfer step performed). If omitted gtransfer will
                        automatically generate a name for the logfile(s).

[--auto-clean|-a]       Remove logfiles automatically after the transfer
                        completed.

[--configfile configurationFile]
                        Determine the name of the configuration file for
                        gtransfer. If not set, this defaults to:

                        "/opt/gtransfer/etc/gtransfer.conf" or

                        "/etc/opt/gtransfer/gtransfer.conf" or

                        "$HOME/.gtransfer/gtransfer.conf" in this order.

[--guc-max-retries gucMaxRetries]
                        Set the maximum number of retries globus-url-copy (guc)
                        will do for a transfer of a single file. By default this
                        is set to 1, which means that guc will tolerate at max.
                        one transfer error per file and retry the transfer once.
                        Alternatively this option can also be set through the
                        environment variable "GUC_MAX_RETRIES".                        

[--gt-max-retries gtMaxRetries]
                        Set the maximum number of retries gt will do for a
                        single transfer step. By default this is set to 3, which
                        means that gt will try to finish a single transfer step
                        three times or fail. Alternatively this option can also
                        be set through the environment variable
                        "GT_MAX_RETRIES".

[--gt-progress-indicator indicatorCharacter]
                        Set the character to use for the progress indicator of
                        gtransfer. By default this is a ".".

[-- gsiftpParameters]   Determine the "globus-url-copy" parameters that should
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

        #  included for thread safety
        local _scanResult=$( mktemp .scanResult_XXXXXX )

	echo "open $targetSiteHostname $targetPort" | telnet 2>/dev/null 1> $_scanResult &

	scanCommandPid="$!"

	kill_after_timeout "$scanCommandPid" "2" &

	wait $scanCommandPid &>/dev/null

	if cat "$_scanResult" | grep "Connected" &>/dev/null; then
		rm "$_scanResult" &>/dev/null
		return 0
	else
		rm "$_scanResult" &>/dev/null
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

getPortNumberFromURL()
{
        #  get the port number from a URL
        #
        #  usage:
        #+ getPortNumberFromUrl url

        local _url="$1"

        local _portNumber=$( echo "$_url" | cut -d ':' -f 3 | cut -d '/' -f 1 )

        if [[ "$_portNumber" != "" ]]; then
                echo "$_portNumber"
                return
        else
                return 1
        fi
}

getFQDNFromURL()
{
        #  get the Fully Qualified Domain Name from a URL
        #
        #  usage:
        #+ getFQDNFromURL url

        local _url="$1"

        local _fqdn=$( getURLWithoutPath "$_url" | cut -d '/' -f 3 | cut -d ':' -f 1)

        if [[ "$_fqdn" != "" ]]; then
                echo "$_fqdn"
                return
        else
                return 1
        fi
}

getURLWithoutPath()
{
	#  determines the URL portion that consists of the protocol id, the
	#+ domain name and the port, or "file://":
	#
	#  (gsiftp://venus.milkyway.universe:2811)/path/to/file
	#  (file://)/path/to/local/file
        #  (gsiftp://user@host.domain:2811)/path/to/file
        #
        #  conserves any existing username portions
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
        #  1 true, 0 false
	if [[ $verboseExec -eq 1 ]]; then
		echo $@
	fi

	return		
}

catIfVerbose()
{
        #  1 true, 0 false
        if [[ $verboseExec -eq 1 ]]; then
	    cat $@
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
	#+                            logfileName \
        #+                            transferId \
	#+                            fromTransitSite \
        #+                            toTransitSite \
        #+                            transitDirUrl

	local source="$1"
	local destination="$2"
	local gsiftpParams="$3"
	local logfileName="$4"
        local transferId="$5"
        #  transfer from transit site? yes (1) / no (0)
	local fromTransitSite="$6"
        #  transfer to transit site? yes (1) / no (0)
        local toTransitSite="$7"
        local transitDirUrl="$8"

        #+ To support multiple concurrent transfers, "$tgftpTransferCommand" must be
        #+ a unique name. One could use the transfer id as prefix:
        #+
        #+ 6dd5928ca873099a381e465afecfa9ef22071c8a.$tgftpTransferCommand
        #+
        #+ NOTICE:
        #+ The transfer id should be calculated from the complete source and
        #+ destination URLs with sha1sum.
        #+ TODO:
        #+ Currently this is done differently. Change this.
        local tgftpTransferCommandSuffix="tgftpTransferCommand"
        local tgftpTransferCommand="$transferId.$tgftpTransferCommandSuffix"

	local tgftpPostCommandParam=""
	local tgftpPostCommand=""

        local gucMaxRetries="${GUC_MAX_RETRIES:-$gucMaxRetries}"

        #  This should create a unique filename correspondent to this specifc tgftp
        #+ command.
        local dumpfileName="${transferId}.dumpfile"

        #  add additional guc parameters
        #
        #  This will enable:
        #+ * restart functionality of guc
        #+ * restart exactly one times
        #+ * create a dumpfile which will contain file that failed to transfer
        #+ * consider 30 seconds without transferred data as stall (meaning: after
        #+   30 secs of time without data transferred, the transfer (of a file) is
        #+   restarted)
        local addGsiftpParams="-restart -rst-retries $gucMaxRetries -dumpfile $dumpfileName -stall-timeout 30"

        #+ Filter "-pp" from "gsiftpParams", as pipelining and reliability don't
        #+ work well in conjunction.
        #
        #  only remove the "-pp" param, because this will leave two spaces at the
        #+ position where "-pp" was removed. This way one can detect that a param
        #+ was removed by gt.
        gsiftpParams=$( echo "$gsiftpParams" | sed -e 's/-pp//' )

	#  Do this only if uberftp is available!
        if hash uberftp &>/dev/null; then
                #  If a transit site is involved as source, the temporary transit
        	#+ directory will be removed after the transfer succeeded.
                if [[ $fromTransitSite -eq 1 ]]; then
                        tgftpPostCommandParam="--post-command"
                        #  remove the whole temp. transit dir from the transit site
                        tgftpPostCommand="uberftp -rm -r $( getURLWithoutPath $source )$( getPathFromURL $source ) &"
                fi

                #  workaround a guc limitation: guc by default creates dirs group and
                #+ world r-x, this makes sure, that the transit dir is only accessible
                #+ by the owner (create and chmod happen prior to the transfer).
                #
                #  NOTICE:
                #+ This was tested on Louhi (with GT5.0.3). There needs to be a short
                #+ sleep between dir creation and chmod, as otherwise the chmod fails.
                #+
                #+ $ uberftp -mkdir gsiftp://p6012-deisa.huygens.sara.nl:2812/scratch/shared/prace/gridftp/transitSiteTempDir.rQoM5180 && uberftp -chmod 0700 gsiftp://p6012-deisa.huygens.sara.nl:2812/scratch/shared/prace/gridftp/transitSiteTempDir.rQoM5180
                #+ Failed to connect to 145.100.18.152 port 2812: Cannot assign requested address 
                #+
                #+ $ uberftp -mkdir gsiftp://p6012-deisa.huygens.sara.nl:2812/scratch/shared/prace/gridftp/transitSiteTempDir.rQoM5180 && sleep 0.5 &&  uberftp -chmod 0700 gsiftp://p6012-deisa.huygens.sara.nl:2812/scratch/shared/prace/gridftp/transitSiteTempDir.rQoM5180
                if [[ $toTransitSite -eq 1 ]]; then                     
                        #  get FQDN and port number from destination URL
                        local _fqdn=$( getFQDNFromURL "$destination" )
                        local _portNumber=$( getPortNumberFromURL "$destination" )
                        local _transitDir=$( getPathFromURL "$transitDirUrl" )

                        tgftpPreCommandParam="--pre-command"
                        #tgftpPreCommand="uberftp -mkdir $transitDirUrl && sleep 0.5 && uberftp -chmod 0700 $transitDirUrl"
                        #  Alternative to the commands above which works around the issue mentioned above. Which wasn't really
                        #+ solved with the short sleep.
                        tgftpPreCommand="echo 'mkdir $_transitDir; chmod 0700 $_transitDir; bye' | uberftp -P $_portNumber $_fqdn"
                fi
        fi

        #  always remove dumpfile if it is empty after a transfer. This is
	#+ because otherwise guc complains about an empty dumpfile and does
	#+ not make a transfer using the commandline arguments.
	if [[ ! -z $tgftpPostCommand ]]; then
		tgftpPostCommand="$tgftpPostCommand if [[ ! -s $dumpfileName ]]; then rm $dumpfileName; fi"
	else
                tgftpPostCommandParam="--post-command"
		tgftpPostCommand="if [[ ! -s $dumpfileName ]]; then rm $dumpfileName; fi"
	fi

	########################################################################

        #  new

        #  case
        #  |
        #  |  verbose (0 false, 1 true)
        #  |  |
        #  |  | fromTransitSite (0 false, 1 true)
        #  |  | |
        #  |  | | toTransitSite (0 false, 1 true)
        #  |  | | |
        #  4  1 0 0 source -> dest
        #  5  1 0 1 source -> transit
        #  8  1 1 1 transit -> transit
        #  6  1 1 0 transit -> dest
        #
        #  0  0 0 0 source -> dest
        #  1  0 0 1 source -> transit
        #  3  0 1 1 transit -> transit
        #  2  0 1 0 transit -> dest

        #  case 4
        if [[ $verboseExec -eq 1 && \
              $fromTransitSite -eq 0 && \
              $toTransitSite -eq 0 \
        ]]; then
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- "-dbg" \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 5
        elif [[ $verboseExec -eq 1 && \
                $fromTransitSite -eq 0 && \
                $toTransitSite -eq 1 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPreCommandParam" \"$tgftpPreCommand\" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- "-dbg" \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 8
        elif [[ $verboseExec -eq 1 && \
                $fromTransitSite -eq 1 && \
                $toTransitSite -eq 1 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPreCommandParam" \"$tgftpPreCommand\" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- "-dbg" \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 6
        elif [[ $verboseExec -eq 1 && \
                $fromTransitSite -eq 1 && \
                $toTransitSite -eq 0 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- "-dbg" \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 0
        elif [[ $verboseExec -eq 0 && \
                $fromTransitSite -eq 0 && \
                $toTransitSite -eq 0 \
        ]]; then
		echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 1
        elif [[ $verboseExec -eq 0 && \
                $fromTransitSite -eq 0 && \
                $toTransitSite -eq 1 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPreCommandParam" \"$tgftpPreCommand\" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 3
        elif [[ $verboseExec -eq 0 && \
                $fromTransitSite -eq 1 && \
                $toTransitSite -eq 1 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPreCommandParam" \"$tgftpPreCommand\" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        #  case 2
        elif [[ $verboseExec -eq 0 && \
                $fromTransitSite -eq 1 && \
                $toTransitSite -eq 0 \
        ]]; then
                echo "tgftp" \
                     "--source \"$source\"" \
                     "--target \"$destination\"" \
		     "--log-filename \"$logfileName\"" \
                     "--force-log-overwrite" \
                     "$tgftpPostCommandParam" \"$tgftpPostCommand\" \
                     "-- \"$gsiftpParams\" \"$addGsiftpParams\"" > "$tgftpTransferCommand"

        fi

        ########################################################################

	if [[ $? -eq 0 ]]; then
        echo "$tgftpTransferCommand"
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

################################################################################
# NEW CODE #####################################################################
################################################################################
getTransferIdForSourceDest()
{
    #  returns the transfer id for source and destination
    #
    #  usage:
    #+ getTransferIdForSourceDest source destination

    local source="$1"
    local destination="$2"

    local transferId=""    

    transferId=$( echo "$source;$destination" | sha1sum | cut -d ' ' -f 1 )
    
    echo "$transferId"

    return
}

getTransferIdForTransfersFile()
{
    #  returns the transfer id for the given transfers file
    #
    #  usage:
    #+ getTransferIdForTransfersFile transfersFile
    
    local transfersFile="$1"

    local transferId=""

    if [[ -e "$transfersFile" ]]; then
        transferId=$( sha1sum < "$transfersFile" | cut -d ' ' -f 1 )
        echo "$transferId"
        return
    else
        return 1
    fi
}


doTransferStep()
{
	#  performs the actual transfer step
	#
	#  usage:
	#+ doTransferStep transferStepSource\
        #+                transferStepDestination \
        #+                transferStepNumber \
        #+                transitSiteTempDir \
        #+                sourcePath \
        #+                destinationPath \
        #+                sourceFile \
        #+                destinationFile \
        #+                sourceUsernamePortion \
        #+                destinationUsernamePortion \
        #+                transferId

        local transferStepSource="$1"
        local transferStepDestination="$2"
        local transferStepNumber="$3"

        local transitSiteTempDir="$4"

        local sourcePath="$5"
        local destinationPath="$6"

        local sourceFile="$7"
        if [[ "$sourceFile" == " " ]]; then
                sourceFile=""
        fi
        local destinationFile="$8"
        if [[ "$destinationFile" == " " ]]; then
                destinationFile=""
        fi

        local sourceUsernamePortion="$9"
        local destinationUsernamePortion="${10}"

        local transferId="${11}"

        #echo "($$) DEBUG: transferStepSource=\"$transferStepSource\""
        #echo "($$) DEBUG: transferStepDestination=\"$transferStepDestination\""
        #echo "($$) DEBUG: transferStepNumber=\"$transferStepNumber\""
        #echo "($$) DEBUG: transitSiteTempDir=\"$transitSiteTempDir\""
        #echo "($$) DEBUG: sourcePath=\"$sourcePath\""
        #echo "($$) DEBUG: destinationPath=\"$destinationPath\""
        #echo "($$) DEBUG: sourceFile=\"$sourceFile\""
        #echo "($$) DEBUG: destinationFile=\"$destinationFile\""
        #echo "($$) DEBUG: sourceUsernamePortion=\"$sourceUsernamePortion\""
        #echo "($$) DEBUG: destinationUsernamePortion=\"$destinationUsernamePortion\""
        #echo "($$) DEBUG: transferId=\"$transferId\""
        #exit 1

	local transferStepSourceWithoutPath=$(getURLWithoutPath "$transferStepSource")
	local transferStepDestinationWithoutPath=$(getURLWithoutPath "$transferStepDestination")

	#  check if connection to source and destination is possible
	if ! checkConnection "$transferStepSourceWithoutPath" && ! checkConnection "$transferStepDestinationWithoutPath"; then
		echo "ERROR: Cannot connect to neither \"$transferStepSourceWithoutPath\" nor \"$transferStepDestinationWithoutPath\"!"
		return 2
	elif ! checkConnection "$transferStepSourceWithoutPath"; then
		echo "ERROR: Cannot connect to \"$transferStepSourceWithoutPath\"!"
		return 2
	elif ! checkConnection "$transferStepDestinationWithoutPath"; then
		echo "ERROR: Cannot connect to \"$transferStepDestinationWithoutPath\"!"
		return 2
	fi

	#  (0) construct names for logfile and dumpfile
        ########################################################################
        local tgftpLogfileName="${tgftpTempLogfileName/%.log/__step_${transferStepNumber}.log}"

	#  get default params for the transfer step
	#+ (1) get filename for default params
        ########################################################################
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
        ########################################################################
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
                #  user params specified
		transferStepDefaultParams="$(xtractXMLAttributeValue "gsiftp_params" $transferStepDefaultParamsFile)"

                #  if user only provided "-len|-partial-length [...]", then just add it to the default gsiftp params,
                #+ if not only use the user provided params.
		grepMatch=$( echo "$gsiftpUserParams" | egrep -o "\-len [[:alnum:]]*|\-partial-length [[:alnum:]]*" )
		if [[ "$grepMatch" == "$gsiftpUserParams" ]]; then
			transferStepDefaultParams="$transferStepDefaultParams $gsiftpUserParams"
		else
			transferStepDefaultParams="$gsiftpUserParams"
		fi
	
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
        ########################################################################
	#  direct transfer
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

		local tgftpTransferCommand=$( createTgftpTransferCommand \
                                              "${transferStepSource}${sourcePath}${sourceFile}" \
                                              "${transferStepDestination}${destinationPath}${destinationFile}" \
                                              "$transferStepDefaultParams" \
                                              "$tgftpLogfileName" \
                                              "$transferId" \
                                              "0" \
                                              "0" \
                                              "" )

		#simulateTransfer

		if [[ $? != 0 ]]; then
			echo "ERROR: tgftp transfer command couldn't be created!"
			exit 1
		fi

                catIfVerbose "$tgftpTransferCommand"

		bash $tgftpTransferCommand &>"${tgftpTransferCommand}Output" &
		
	#  initial transfer step of a multi-step transfer (source to transit site)
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

		local tgftpTransferCommand=$( createTgftpTransferCommand \
                                              "${transferStepSource}${sourcePath}${sourceFile}" \
                                              "${transferStepDestination}${transitSiteTempDir}/" \
                                              "$transferStepDefaultParams" \
                                              "$tgftpLogfileName" \
                                              "$transferId" \
                                              "0" \
                                              "1" \
                                              "${transferStepDestination}${transitSiteTempDir}/" )
        
		#simulateTransfer
		#simulateError

		if [[ $? != 0 ]]; then
			echo "ERROR: tgftp transfer command couldn't be created!"
			exit 1
		fi

                catIfVerbose "$tgftpTransferCommand"

		bash $tgftpTransferCommand &>"${tgftpTransferCommand}Output" &

	#  transfer (transit site to transit site)
	#
	#  A transfer from transit site to transit site can be
	#+ detected as follows:
	#+ A transit address has a temp path added to the URL
	#+ and therefore should differ from the string printed
	#+ by getURLWithoutPath().
	elif [[ "$transferStepDestination" != "$(getURLWithoutPath $transferStepDestination)" ]]; then

		local tgftpTransferCommand=$( createTgftpTransferCommand \
                                              "${transferStepSource}${transitSiteTempDir}/${sourceFile}" \
                                              "${transferStepDestination}${transitSiteTempDir}/" \
                                              "$transferStepDefaultParams" \
                                              "$tgftpLogfileName" \
                                              "$transferId" \
                                              "1" \
                                              "1" \
                                              "${transferStepDestination}${transitSiteTempDir}/" )

		#simulateTransfer

                catIfVerbose "$tgftpTransferCommand"

		bash $tgftpTransferCommand &>${tgftpTransferCommand}Output &

	#  last step (transit site to final destination)
	#
	#  The last step is identified by the transfer step
	#+ target being identical to the target of the data
	#+ path, which itself is identical to the target without
	#+ path portion.
	elif [[ "$transferStepDestination" == "$(getURLWithoutPath $transferStepDestination)" ]]; then
		
		#  handle usernames in URLs
		transferStepDestinationProtoSpec=$( getProtocolSpecifier $transferStepDestination )
		#  replace protocol spec with proto. spec and username (don't forget "@" at the end)
		#  NOTICE:
		#+ Please be aware of the fact, that the shell expands the variables in the sed scripts before actually running the sed scripts.
		#+ As the proto. spec contains "/"es. they must be either escaped (hard!) or one just changes the "/"es of the "s///" command to
		#+ "|"s.
		transferStepDestination=$( echo $transferStepDestination | sed -e "s|${transferStepDestinationProtoSpec}|${transferStepDestinationProtoSpec}${destinationUsernamePortion}|" )

		local tgftpTransferCommand=$( createTgftpTransferCommand \
                                              "${transferStepSource}${transitSiteTempDir}/${sourceFile}" \
                                              "${transferStepDestination}${destinationPath}${destinationFile}" \
                                              "$transferStepDefaultParams" \
		                              "$tgftpLogfileName" \
                                              "$transferId" \
		                              "1" \
                                              "0" \
                                              "" )

                catIfVerbose "$tgftpTransferCommand"

		#simulateTransfer
		#simulateError

		bash $tgftpTransferCommand &>${tgftpTransferCommand}Output &

	fi

	tgftpTransferCommandPid="$!"

	#  indicate progress
	while ps -p$tgftpTransferCommandPid &>/dev/null; do
		echo -n "$gtProgressIndicator"
		sleep 2
	done

	echoIfVerbose ""

	wait $tgftpTransferCommandPid

	local RETURN="$?"

        #  save finished state, just in case another step fails and gtransfer exits
        #+ and is then restarted by the user. This way, finished steps aren't
        #+ repeated. If all steps finish/succeed, the finished state files can be
        #+ removed by gtransfer.
        #
        #  transferId is either the SHA1 hash of source;destination, or the hash of
        #+ the used transfers file.
        if [[ "$RETURN" == "0" ]]; then
                touch "${transferId}.finished"
                rm -f "$tgftpTransferCommand" &>/dev/null
                rm -f "${tgftpTransferCommand}Output" &>/dev/null
        else
        #  if transfer step failed print the output of the tgftp command
                cat ${tgftpTransferCommand}Output
        fi

	#echo "Returned $RETURN"

	return $RETURN
}


transferData()
{
	#  transfers data from source to target (new version!)
	#
	#  usage:
	#+ transferData source destination metric tmpLogfileName

	#  TODO:
	#
	#  If a source URL ends with "/" or "/*", the target URL has to end with
	#+ "/". Make sure this is the case!

	local source="$1"
	local destination="$2"
	local dataPathMetric="$3"
	local tgftpTempLogfileName="$4"
	local tgftpLogfileName=""

        #  max number of retries gtransfer will do
        local maxRetries="${GT_MAX_RETRIES:-$gtMaxRetries}"
        local retries=0

	#  Check if valid URLs are provided
	if ! isValidUrl $source; then
		echo "ERROR: Protocol specifier missing in \"$source\" and no local path specified!"
		exit 1
	elif ! isValidUrl $destination; then
		echo "ERROR: Protocol specifier missing in \"$destination\" and no local path specified!"
		exit 1
	#  check if target URL is a "http://" URL
	elif [[ "$( getProtocolSpecifier $destination )" == "http://" || \
	        "$( getProtocolSpecifier $destination )" == "https://" \
	]]; then
		echo "ERROR: Target URL cannot be a \"http[s]://\" URL!"
		exit 1
	fi

	local sourceWithoutPath=$(getURLWithoutPath "$source")
	local destinationWithoutPath=$(getURLWithoutPath "$destination")

	local sourcePath=$(getPathFromURL "$source")
	local destinationPath=$(getPathFromURL "$destination")

	local sourceFile=$(getFilenameFromURL "$source")
	local destinationFile=$(getFilenameFromURL "$destination")

        local sourceUsernamePortion=$( echo $sourceWithoutPath | grep -o "://.*@" | sed -e 's/:\/\///' )
	local destinationUsernamePortion=$( echo $destinationWithoutPath | grep -o "://.*@" | sed -e 's/:\/\///' )

	local memToMem=1

	#  is this a memory to memory transfer?
	if [[ "${sourcePath}${sourceFile}" == "/dev/zero" && \
	      "${destinationPath}${destinationFile}" == "/dev/null" \
	]]; then
		memToMem=0
	fi

        #echo "($$) DEBUG: source=\"$source\""
        #echo "($$) DEBUG: destination=\"$destination\""
        #echo "($$) DEBUG: sourceWithoutPath=\"$sourceWithoutPath\""
        #echo "($$) DEBUG: destinationWithoutPath=\"$destinationWithoutPath\""
        #echo "($$) DEBUG: sourcePath=\"$sourcePath\""
        #echo "($$) DEBUG: destinationPath=\"$destinationPath\""
        #echo "($$) DEBUG: sourceFile=\"$sourceFile\""
        #echo "($$) DEBUG: destinationFile=\"$destinationFile\""
        #echo "($$) DEBUG: sourceUsernamePortion=\"$sourceUsernamePortion\""
        #echo "($$) DEBUG: destinationUsernamePortion=\"$destinationUsernamePortion\""
        #exit 1

	#  get corresponding data path (and remove any "username@" portions in
	#+ the URL before hashing).
	local dataPathFilename="$(hashSourceDestination $( echo $sourceWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) $( echo $destinationWithoutPath | sed -e 's/:\/\/.*@/:\/\//' ) )"

	if [[ -e "$gtransferDataPathDirectory/$dataPathFilename" ]]; then
		local dataPathFile="$gtransferDataPathDirectory/$dataPathFilename"
	elif [[ -e "$gtransferSystemDataPathDirectory/$dataPathFilename" ]]; then
		local dataPathFile="$gtransferSystemDataPathDirectory/$dataPathFilename"
	fi

	#  temporary dir on transit site. This is the same for all transit sites.
        #+ To finish a failed transfer its name is also stored in a file until the
        #+ whole transfer is finished.
	#
	#  NOTICE:
	#+ This contains no leading/trailing "/"!
        if [[ -e "$dataPathFilename".transitSiteTempDir ]]; then
                local transitSiteTempDir=$( cat "$dataPathFilename".transitSiteTempDir )
        else
                local transitSiteTempDir=$( mktemp -u "transitSiteTempDir.XXXXXXXX" )
                echo "$transitSiteTempDir" > "$dataPathFilename".transitSiteTempDir
        fi

	#  data path file existing?
	if [[ -e "$dataPathFile" && \
	      $memToMem != 0 \
	]]; then
		#  yes, initiate transfers along the path

		echoIfVerbose -e "Data path used:\n$dataPathFile"

		local transferStepNumber=0

		local -a transferStepArray=( $(xtractXMLAttributeValue "path metric=\"$dataPathMetric\"" $dataPathFile) )

		local maxTransferStepNumber=${#transferStepArray[@]}

        else

                #  no, try a direct transfer.
		local transferStepNumber=0

                local -a transferStepArray[0]="$sourceWithoutPath;$destinationWithoutPath"

		local maxTransferStepNumber=1

        fi        

        #echo "($$) DEBUG: retries=\"$retries\" maxRetries=\"$maxRetries\""
        #exit

	while [[ 1 ]]; do

                if [[ $transferStepNumber -ge $maxTransferStepNumber ]]; then
                        break
                fi

                local transferStep=${transferStepArray[$transferStepNumber]}

                #  source and destination for transfer step
                local transferStepSource=${transferStep%%;*}
                local transferStepDestination=${transferStep##*;}

                #echo "($$) DEBUG: transferStepSource=\"$transferStepSource\""
                #echo "($$) DEBUG: transferStepDestination=\"$transferStepDestination\""
                #exit 1

                local transferId=$( getTransferIdForSourceDest "$transferStepSource" "$transferStepDestination" )

                #  if the current transfer step is/was already finished, skip it.
                if [[ -e "$transferId.finished" ]]; then
                        echoIfVerbose "Transfer step: $transferStepNumber"
                        echoIfVerbose "Skipped because already finished!"
                        transferStepNumber=$(( $transferStepNumber + 1 ))
                        continue
                else
                        echoIfVerbose "Transfer step: $transferStepNumber"
                        doTransferStep $transferStepSource \
                                       $transferStepDestination \
                                       $transferStepNumber \
                                       $transitSiteTempDir \
                                       $sourcePath \
                                       $destinationPath \
                                       ${sourceFile:-" "} \
                                       ${destinationFile:-" "} \
                                       "$sourceUsernamePortion" \
                                       "$destinationUsernamePortion" \
                                       $transferId
                fi

		local RETURN="$?"

		#  did the current transfer step work?
		if [[ $? == 2 ]]; then
			#  no, it failed completely
        	        echoIfVerbose ""
			echoIfVerbose "ERROR: Transfer step #$transferStepNumber failed!" #\
                                 #"Please see \"${tgftpTransferCommand}Output\" for details!"
			exit 1

		elif [[ $RETURN -ne 0 && "$retries" -lt "$maxRetries" ]]; then
                         retries=$(( $retries + 1 ))
			#  no
			echoIfVerbose ""
			echoIfVerbose "ERROR: Transfer step #$transferStepNumber failed! Retrying!" #\
                                 #"Please see \"${tgftpTransferCommand}Output\" for details!"
       
		elif [[ $RETURN -eq 0 ]]; then
			#  yes
                        retries="0"
			#rm -f "$transferId".* &>/dev/null
			transferStepNumber=$(( $transferStepNumber + 1 ))

                elif [[ "$retries" -eq "$maxRetries" ]]; then
                        echo ""
                        echo "ERROR: Transfer step #$transferStepNumber failed after $retries retries! Exiting."
                        exit 1

		fi

	done
	
        #  if the whole transfer succeeded,
        if [[ "$?" == "0" ]]; then
                #  reactivate filename globbing for temp file deletion
                set +f
                #  ...remove temporary files
                #  file with name of transit site temporary dir
                rm -f "$dataPathFilename".transitSiteTempDir &>/dev/null
                #  any finished transfer step markers
                rm -f *.finished &>/dev/null
                #  temporary file(s) containing the running tgftp transfer command(s)
                #+ and its output.
                #rm -f *."$tgftpTransferCommand"* &>/dev/null
        fi

	echoIfVerbose -e "INFO: The transfer succeeded!"

	if [[ $gtProgressIndicatorSet != 0 ]]; then
		echo ""
	fi

}
################################################################################

#  load plugins
#
#  NOTICE:
#+ This works as follows: If a function with the same name as another function
#+ is defined after that other function, the last one "wins" and is used in the
#+ script.
#+ To ease handling and understanding, one should use the following rules for
#+ plugins:
#+
#+ * use a specific header (including a shabang, so one can test the function
#+   before including it)
#+
#+ * use one function per plugin
#+
#+ * name the plugin after the function
#+
#+ Currently this only allows to exchange function bodies and one has to make
#+ sure that the new function uses the same interface as the old function as
#+ otherwise the whole script could malfunction.
#+ But one could also think of "real" plugins, that could plug into specific
#+ functions of gt in order to change functionality or behaviour. The new
#+ reliability functions could have been integrated with such a functionality,
#+ for example.
gtransferPluginDir=$( dirname $gtransferConfigurationFile/plugins )
for plugin in $(ls -1 $gtransferPluginDir ); do
	#  plugins are activated by making them readable AND executable!
	if [[ -r "$gtransferPluginDir/$plugin" && -x "$gtransferPluginDir/$plugin" ]]; then
		. "$gtransferPluginDir/$plugin"
	fi
done

################################################################################

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

gtMaxRetries="3"
gucMaxRetries="1"
gtProgressIndicator="."

#  correct number of params?
if [[ "$#" -lt "1" ]]; then
   # no, so output a usage message
   usageMsg
   exit $_gtransfer_exit_usage
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
                "$1" != "--guc-max-retries" && \
                "$1" != "--gt-max-retries" && \
                "$1" != "--transfer-list" && "$1" != "-f" && \
                "$1" != "--gt-progress-indicator" && \
                "$1" != "--auto-optimize" && "$1" != "-o" && \
		"$1" != "--" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit $_gtransfer_exit_usage
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
		exit $_gtransfer_exit_ok

	#  "--version|-V"
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then
		versionMsg
		exit $_gtransfer_exit_ok

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
			exit $_gtransfer_exit_usage
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
			exit $_gtransfer_exit_usage
		fi

        #  "--transfer-list|-f transferList"
	elif [[ "$1" == "--transfer-list" || "$1" == "-f" ]]; then
		if [[ "$gsiftpTransferListSet" != "0" ]]; then
			shift 1
			gsiftpTransferList="$1"
			gsiftpTransferListSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--transfer-list|-f\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
		fi
		
	#  "--auto-optimize|-o transferMode"
	elif [[ "$1" == "--auto-optimize" || "$1" == "-o" ]]; then
		if [[ "$autoOptimizeSet" != "0" ]]; then
			shift 1
			transferMode="$1"
			autoOptimizeSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--auto-optimization|-o\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
		fi

        #  "--guc-max-retries gucMaxRetries"
	elif [[ "$1" == "--guc-max-retries" ]]; then
		if [[ "$gucMaxRetriesSet" != "0" ]]; then
			shift 1
			gucMaxRetries="$1"
			gucMaxRetriesSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--guc-max-retries\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
		fi

        #  "--gt-max-retries gtMaxRetries"
	elif [[ "$1" == "--gt-max-retries" ]]; then
		if [[ "$gtMaxRetriesSet" != "0" ]]; then
			shift 1
			gtMaxRetries="$1"
			gtMaxRetriesSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--gt-max-retries\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
		fi

        #  "--gt-progress-indicator indicatorCharacter"
        elif [[ "$1" == "--gt-progress-indicator" ]]; then
		if [[ "$gtProgressIndicatorSet" != "0" ]]; then
			shift 1
			gtProgressIndicator="$1"
			gtProgressIndicatorSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--gt-progress-indicator\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
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
			exit $_gtransfer_exit_usage
		fi

	#  "--verbose|-v"
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
		if [[ $verboseExecSet != 0 ]]; then
			shift 1
			verboseExecSet=0
		else
			#  duplicate usage of this parameter
			echo "ERROR: The parameter \"--verbose|-v\" cannot be used multiple times!"
			exit $_gtransfer_exit_usage
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
			exit $_gtransfer_exit_usage
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
			exit $_gtransfer_exit_usage
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
			exit $_gtransfer_exit_usage
		fi

	fi

done

#  load configuration file
if [[ -e "$gtransferConfigurationFile" ]]; then
	. "$gtransferConfigurationFile"
else
	echo "ERROR: gtransfer configuration file missing!"
	exit $_gtransfer_exit_software
fi

#  verbose execution needed due to options?
if [[ $verboseExecSet == 0 ]]; then
	verboseExec=1
fi

#  auto optimization requested?
if [[ $autoOptimizeSet == 0 ]]; then
	autoOptimize=1 # 1 on, 0 off
fi

#  set dpath metric
if [[ "$dataPathMetricSet" != "0" ]]; then
	dataPathMetric="$defaultDataPathMetric"
fi

#  set logfile name
if [[ "$tgftpLogfileNameSet" != "0" ]]; then
	tgftpLogfileName="$defaultTgftpLogfileName"
fi

#  all mandatory params present?
if [[ "$gsiftpSourceUrl" == "" || \
      "$gsiftpDestinationUrl" == "" \
]]; then
        if [[ "$gsiftpTransferListSet" == "0" ]]; then
        	#  TODO:
        	#  Use temporary dir for temp files (.gtransfer/<transferID>)
        	#  1. Determine transfer id for original transfer list
        	#  2. Create temp dir and store path in global var
        	if [[ "$autoOptimize" -eq 1 ]]; then
        		autoOptimization/performTransfer "$gsiftpTransferList"  "$dataPathMetric" "$tgftpLogfileName" "$chunkConfig" "$transferMode"
        	else
                	listTransfer/transferData "$gsiftpTransferList" "$dataPathMetric" "$tgftpLogfileName"
                fi
        else
                #  no, so output a usage message
                usageMsg
                exit $_gtransfer_exit_usage
        fi
else
	if [[ "$autoOptimize" -eq 1 ]]; then
		gsiftpTransferList=$( listTransfer/createTransferList "$gsiftpSourceUrl" "$gsiftpDestinationUrl" )
		autoOptimization/performTransfer "$gsiftpTransferList"  "$dataPathMetric" "$tgftpLogfileName" "$chunkConfig" "$transferMode"
	else
        	transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
        fi
fi

#transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
transferDataReturnValue="$?"

#  automatically remove logfiles if needed
if [[ $autoClean == 0 ]]; then
	rm -rf ${tgftpLogfileName/%.log/}*
fi

exit $transferDataReturnValue

