#!/bin/bash
#  gtransfer - wrapper for tgftp with support for:
#+ * datapathing
#+ * default parameter usage
#+ * ...

:<<COPYRIGHT

Copyright (C) 2010, 2011, 2013-2015 Frank Scheiner, HLRS, Universitaet Stuttgart
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

# Reset the signal handler (possibly inherited from the caller) for SIGINT
trap - SIGINT

#  prevent "*" expansion (filename globbing)
#set -f

readonly _program=$( basename "$0" )
readonly _gtransferVersion="0.4.0"

version="$_gtransferVersion"

gsiftpUserParams=""

#  path to configuration files (prefer system paths!)
#  For native OS packages:
if [[ -e "/etc/gtransfer" ]]; then
        gtransferConfigurationFilesPath="/etc/gtransfer"
        #  gtransfer is installed in "/usr/bin", hence the base path is "/usr"
        gtransferBasePath="/usr"
        gtransferLibPath="$gtransferBasePath/share"
        gtransferLibexecPath="$gtransferBasePath/libexec/gtransfer"

#  For installation with "install.sh".
#sed#elif [[ -e "<GTRANSFER_BASE_PATH>/etc" ]]; then
#sed#	gtransferConfigurationFilesPath="<GTRANSFER_BASE_PATH>/etc"
#sed#	gtransferBasePath=<GTRANSFER_BASE_PATH>
#sed#	gtransferLibPath="$gtransferBasePath/lib"
#sed#	gtransferLibexecPath="$gtransferBasePath/libexec"

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
        gtransferLibexecPath="$gtransferBasePath/libexec"

#  For user install in $HOME:
#elif [[ -e "$HOME/.gtransfer" ]]; then
elif [[ -e "$HOME/opt/gtransfer" ]]; then
        gtransferConfigurationFilesPath="$HOME/.gtransfer"
        gtransferBasePath="$HOME/opt/gtransfer"
        gtransferLibPath="$gtransferBasePath/lib"
        gtransferLibexecPath="$gtransferBasePath/libexec"

#  For git deploy, use $BASH_SOURCE
elif [[ -e "$( dirname $BASH_SOURCE )/../etc" ]]; then
	gtransferConfigurationFilesPath="$( dirname $BASH_SOURCE )/../etc/gtransfer"
	gtransferBasePath="$( dirname $BASH_SOURCE )/../"
	gtransferLibPath="$gtransferBasePath/lib"
	gtransferLibexecPath="$gtransferBasePath/libexec"
fi

gtransferConfigurationFile="$gtransferConfigurationFilesPath/gtransfer.conf"

chunkConfig="$gtransferConfigurationFilesPath/chunkConfig"

#  Set $_LIB so gtransfer and its libraries can find their includes
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

readonly __GLOBAL__gtTmpSuffix="#gt#tmp#"
readonly __GLOBAL__gtCacheSuffix="#gt#cache#"

readonly _true=1
readonly _false=0


################################################################################
# INCLUDES
################################################################################

_neededLibraries=( "gtransfer/exitCodes.bashlib"
                   "gtransfer/urlTransfer.bashlib"
                   "gtransfer/listTransfer.bashlib"
                   "gtransfer/autoOptimization.bashlib"
                   "gtransfer/pids/irodsMicroService.bashlib"
                   "gtransfer/multipathing.bashlib" )

for _library in ${_neededLibraries[@]}; do

	if ! . "$_LIB/$_library" 2>/dev/null; then
		echo "$_program: Library \"$_LIB/$_library\" couldn't be read or is corrupted." 1>&2
		exit 70
	fi
done


################################################################################
#  FUNCTIONS
################################################################################

#USAGE##########################################################################
usageMsg()
{
        cat <<USAGE

usage: $(basename $0) --source|-s sourceUrl --destination|-d destinationUrl [additional options]
       $(basename $0) --transfer-list|-f transferList [additional options]
       $(basename $0) [--help]

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

$(basename $0) --source|-s sourceUrl --destination|-d destinationUrl [additional options]
$(basename $0) --transfer-list|-f transferList [additional options]


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

[--transfer-list|-f transferList]
			As alternative to providing source and destination URLs
			on the commandline one can also provide a list of source
			and destination URLs. See the gt manual page for more
			details.

[--auto-optimize|-o transferMode]
			Activates automatic optimization of transfers
			depending on the size of files. The transferMode
			controls how files of different size classes are
			transferred. Currently only "seq[uential]" is possible.
			
[--recursive|-r]	Transfer files recursively.

[--checksum-data-channel|-c]
			Enable checksumming on the data channel. Cannot be used
			in conjunction with "-e"!

[--encrypt-data-channel|-e]
			Enable encryption on the data channel. Cannot be used
			in conjunction with "-c"!

[--verbose|-v]		Be verbose.

[--metric|-m dataPathMetric]
			Set the metric to select the corresponding data path. To
			enable multipathing, use either the keyword "all" to
			transfer data using all available paths or use a comma
			separated list with the metric values of the paths that
			should be used (e.g. "0,1,2"). You can also use metric
			values multiple times (e.g. "0,0").

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

			"/etc/gtransfer/gtransfer.conf" or

			"<INSTALL_PATH>/etc/gtransfer.conf" or

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

[-- gucParameters]	Determine the "globus-url-copy" parameters that should
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

[--help]		Prints out a help message.

[--version|-V]		Prints out version information.

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
		echo "$debugLevel: $debugString" 1>$fd
	fi		

	return
}


onExit()
{
	#  on EXIT remove all temporary files (temporary files with the gt tmp
	#+ suffix are recreated at every run and hence can also be savely
	#+ removed on EXIT)
	set +f

	rm -rf ${__GLOBAL__gtTmpDir}/*."$__GLOBAL__gtTmpSuffix"

	return
}


onSigint()
{
	# kill all gt subprocesses (from multipathing)
	for _gtSubProcess in "${_gtSubProcesses[@]}"; do
		kill -SIGINT $_gtSubProcess &>/dev/null
	done

	# restore signal handler to default one
	trap - SIGINT

	# kill self
	kill -SIGINT $$

	return
}
################################################################################

################################################################################
#  MAIN
################################################################################

trap 'onExit' EXIT

trap 'onSigint' SIGINT

#  check that all required tools are available
helperFunctions/use cat grep sed cut sleep tgftp telnet uberftp || exit "$_gtransfer_exit_software"


# Defaults #####################################################################
gtMaxRetries="3"
gucMaxRetries="1"
gtProgressIndicator="."
gtInstance="$gtProgressIndicator"

# 1 means not set (false), 0 means set (true) in this case, as like the
# exit/return value of shell functions/scripts.
dataPathMetricSet="1"
tgftpLogfileNameSet="1"
recursiveTransferSet=1
_checksumDataChannelSet=1
_encryptDataChannelSet=1
################################################################################


#  The temp dir is named after the SHA1 hash of the command line.
readonly __GLOBAL__gtTmpDirName=$( echo "$0 $@" | sha1sum | cut -d ' ' -f 1 )
readonly __GLOBAL__gtTmpDir="$HOME/.gtransfer/tmp/$__GLOBAL__gtTmpDirName"

readonly __GLOBAL__gtCommandLine="$0 $@"

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
                "$1" != "--recursive" && "$1" != "-r" && \
                "$1" != "--checksum-data-channel" && "$1" != "-c" && \
                "$1" != "--encrypt-data-channel" && "$1" != "-e" && \
		"$1" != "--" \
	]]; then
		#  no, so output a usage message
		usageMsg
		exit $_gtransfer_exit_usage
	fi

	#  "--" ################################################################
	if [[ "$1" == "--" ]]; then
		#  remove "--" from "$@"
		shift 1
		#  params forwarded to "globus-url-copy"
		gsiftpUserParams="$@"

		#  exit the loop (this assumes that everything left in "$@" is
		#+ a "globus-url-copy" param).		
		break

	#  "--help" ############################################################
	elif [[ "$1" == "--help" ]]; then
		helpMsg
		exit $_gtransfer_exit_ok

	#  "--version|-V" ######################################################
	elif [[ "$1" == "--version" || "$1" == "-V" ]]; then
		versionMsg
		exit $_gtransfer_exit_ok

	#  "--source|-s gsiftpSourceUrl" #######################################
	elif [[ "$1" == "--source" || "$1" == "-s" ]]; then
		if [[ "$gsiftpSourceUrlSet" != "0" ]]; then
			shift 1
			gsiftpSourceUrl="$1"
			gsiftpSourceUrlSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--source|-s\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--destination|-d gsiftpDestinationUrl" #############################
	elif [[ "$1" == "--destination" || "$1" == "-d" ]]; then
		if [[ "$gsiftpDestinationUrlSet" != "0" ]]; then
			shift 1
			gsiftpDestinationUrl="$1"
			gsiftpDestinationUrlSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--destination|-d\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

        #  "--transfer-list|-f transferList" ###################################
	elif [[ "$1" == "--transfer-list" || "$1" == "-f" ]]; then
		if [[ ! $gsiftpTransferListSet -eq 1 ]]; then
			shift 1
			gsiftpTransferList="$1"
			gsiftpTransferListSet=1
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--transfer-list|-f\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--auto-optimize|-o transferMode" ###################################
	elif [[ "$1" == "--auto-optimize" || "$1" == "-o" ]]; then
		if [[ "$autoOptimizeSet" != "0" ]]; then
			shift 1
			transferMode="$1"
			# By default use "seq" transfer mode
			if [[ -z "$transferMode" ]]; then
				transferMode="seq"
			fi
			autoOptimizeSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--auto-optimization|-o\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

        #  "--guc-max-retries gucMaxRetries" ###################################
	elif [[ "$1" == "--guc-max-retries" ]]; then
		if [[ "$gucMaxRetriesSet" != "0" ]]; then
			shift 1
			gucMaxRetries="$1"
			gucMaxRetriesSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--guc-max-retries\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

        #  "--gt-max-retries gtMaxRetries" #####################################
	elif [[ "$1" == "--gt-max-retries" ]]; then
		if [[ "$gtMaxRetriesSet" != "0" ]]; then
			shift 1
			gtMaxRetries="$1"
			gtMaxRetriesSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--gt-max-retries\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

        #  "--gt-progress-indicator indicatorCharacter" ########################
        elif [[ "$1" == "--gt-progress-indicator" ]]; then
		if [[ "$gtProgressIndicatorSet" != "0" ]]; then
			shift 1
			gtProgressIndicator="$1"
			gtProgressIndicatorSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--gt-progress-indicator\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--metric|-m dataPathMetric" ########################################
	elif [[ "$1" == "--metric" || "$1" == "-m" ]]; then
		if [[ "$dataPathMetricSet" != "0" ]]; then
			shift 1
			dataPathMetric="$1"
			dataPathMetricSet="0"
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--metric|-m\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--verbose|-v" ######################################################
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
		if [[ $verboseExecSet != 0 ]]; then
			shift 1
			verboseExecSet=0
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--verbose|-v\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi
		
	#  "--recursive|-r" ####################################################
	elif [[ "$1" == "--recursive" || "$1" == "-r" ]]; then
		if [[ $recursiveTransferSet != 0 ]]; then
			shift 1
			recursiveTransferSet=0
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--recursive|-r\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--checksum-data-channel|-c" ########################################
	elif [[ "$1" == "--checksum-data-channel" || "$1" == "-c" ]]; then
		if [[ $_checksumDataChannelSet -ne 0 ]]; then

			if [[ $_encryptDataChannelSet -ne 0 ]]; then

				shift 1
				_checksumDataChannelSet=0
			else
				echo "${_program}: The parameter \"--checksum-data-channel|-c\" cannot be used in conjunction with the parameter \"--encrypt-data-channel|-e\"!"
				echo "Try \`${_program} --help' for more information."
				exit $_gtransfer_exit_usage
			fi
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--checksum-data-channel|-c\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--encrypt-data-channel|-e" #########################################
	elif [[ "$1" == "--encrypt-data-channel" || "$1" == "-e" ]]; then
		if [[ $_encryptDataChannelSet -ne 0 ]]; then

			if [[ $_checksumDataChannelSet -ne 0 ]]; then

				shift 1
				_encryptDataChannelSet=0
			else
				echo "${_program}: The parameter \"--encrypt-data-channel|-e\" cannot be used in conjunction with the parameter \"--checksum-data-channel|-c\"!"
				echo "Try \`${_program} --help' for more information."
				exit $_gtransfer_exit_usage
			fi
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--encrypt-data-channel|-e\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage

	#  "--auto-clean|-a" ###################################################
	elif [[ "$1" == "--auto-clean" || "$1" == "-a" ]]; then
		if [[ $autoCleanSet != 0 ]]; then
			shift 1
			autoClean=0
			autoCleanSet=0
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--auto-clean|-a\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--logfile|-l" ######################################################
	elif [[ "$1" == "--logfile" || "$1" == "-l" ]]; then
		if [[ $tgftpLogfileNameSet != 0 ]]; then
			shift 1
			tgftpLogfileName="$1"
			tgftpLogfileNameSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--logfile|-l\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	#  "--configfile" ######################################################
	elif [[ "$1" == "--configfile" ]]; then
		if [[ $gtransferConfigurationFileSet != 0 ]]; then
			shift 1
			gtransferConfigurationFile="$1"
			gtransferConfigurationFileSet=0
			shift 1
		else
			#  duplicate usage of this parameter
			echo "${_program}: The parameter \"--configfile\" cannot be used multiple times!"
			echo "Try \`${_program} --help' for more information."
			exit $_gtransfer_exit_usage
		fi

	fi

done

#  load configuration file
if [[ -e "$gtransferConfigurationFile" ]]; then
	. "$gtransferConfigurationFile"
else
	echo "${_program}: gtransfer configuration file \"$gtransferConfigurationFile\" missing!" 1>&2
	exit $_gtransfer_exit_software
fi

gtInstance="$gtProgressIndicator"

#  verbose execution needed due to options?
if [[ $verboseExecSet == 0 ]]; then
	verboseExec=1
	_verboseOption="-v"
else
	verboseExec=0
	_verboseOption=""
fi

#  auto optimization requested?
if [[ $autoOptimizeSet == 0 ]]; then
	autoOptimize=1 # 1 on, 0 off
else
	autoOptimize=0
fi

#  set dpath metric
if [[ "$dataPathMetricSet" != "0" ]]; then
	dataPathMetric="$defaultDataPathMetric"
elif [[ "$dataPathMetricSet" == "0" ]]; then
	if multipathing/multipleMetricsSet "$dataPathMetric"; then
		_activateMultipathing=1 # true => multipathing activated
	else
		_activateMultipathing=0 # false => multipathing not activated
	fi
fi

#  set logfile name
if [[ "$tgftpLogfileNameSet" != "0" ]]; then
	tgftpLogfileName="$defaultTgftpLogfileName"
fi

#  all mandatory params present?
if [[ "$gsiftpSourceUrl" == "" || \
      "$gsiftpDestinationUrl" == "" \
]]; then
        if [[ $gsiftpTransferListSet -eq 1 ]]; then
		# skip transfer if transfer list is empty
		if [[ ! -s "$gsiftpTransferList" ]]; then
			helperFunctions/echoIfVerbose "${_program} [${gtInstance}]: Skipping empty transfer list."
			exit 0
		fi

		#  create directory for temp files
		mkdir -p "$__GLOBAL__gtTmpDir"
		
		#  strip comment lines from transfer list
		gsiftpTransferListClean="$__GLOBAL__gtTmpDir/$$_transferList.${__GLOBAL__gtTmpSuffix}"
		sed -e '/^#.*$/d' "$gsiftpTransferList" > "$gsiftpTransferListClean"

		_transferListSource=$( listTransfer/getSourceFromTransferList "$gsiftpTransferListClean" )
		_transferListDestination=$( listTransfer/getDestinationFromTransferList "$gsiftpTransferListClean" )
		#_dpath=$( listTransfer/dpathAvailable "$_transferListSource" "$_transferListDestination" )
		_dpath=$( listTransfer/getDpathFile "$_transferListSource" "$_transferListDestination" )

		if [[ $_activateMultipathing -eq 1 ]]; then

			#echo "DEBUG: Multipathing activated!" 1>&2

			#echo "DEBUG: _dpath=\"$_dpath\"" 1>&2

			# create array of metrics
			declare -a _dpathMetricArray
			if [[ "$dataPathMetric" == "all" ]]; then
				_dpathMetricArray=( $( grep '^<path .*metric=' < "$_dpath" | grep -o 'metric="[[:digit:]]*"' | sed -e 's/^metric="//' -e 's/"$//' ) )
			else
				_dpathMetricArray=( $( echo "$dataPathMetric" | tr ',' ' ' ) )
				for _dpathMetric in "${_dpathMetricArray[@]}"; do
					if ! helperFunctions/isValidMetric $_dpath $_dpathMetric; then

						echo "${_program} [${gtInstance}]: Invalid metric value(s) used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
						exit $_gtransfer_exit_usage
					fi
				done
			fi

			multipathing/performTransfer "$gsiftpTransferList" "$_dpath" "$dataPathMetric" "$autoOptimize" "$_verboseOption"

		#  TODO:
		#  Use temporary dir for temp files (.gtransfer/<transferID>)
		#  1. Determine transfer id for original transfer list
		#  2. Create temp dir (e.g. _tempDir=$( echo "$0" "$@" | sha1sum )) and store path in global var
		elif [[ $autoOptimize -eq 1 ]]; then

			if ! helperFunctions/isValidMetric "$_dpath" "$dataPathMetric"; then

				echo "${_program} [${gtInstance}]: Invalid metric value(s) used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
				exit $_gtransfer_exit_usage
			fi

			#  only perform auto-optimization if there are at least
			#+ 100 files in the transfer list. If not perform simple
			#+ list transfer.
			if [[ $( listTransfer/getNumberOfFilesFromTransferList "$gsiftpTransferListClean" ) -ge 100 ]]; then
				autoOptimization/performTransfer "$gsiftpTransferListClean"  "$dataPathMetric" "$tgftpLogfileName" "$chunkConfig" "$transferMode"
			else
				listTransfer/performTransfer "$gsiftpTransferListClean" "$dataPathMetric" "$tgftpLogfileName"
			fi
		else
			if ! helperFunctions/isValidMetric "$_dpath" "$dataPathMetric"; then

				echo "${_program} [${gtInstance}]: Invalid metric value(s) used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
				exit $_gtransfer_exit_usage
			fi

			listTransfer/performTransfer "$gsiftpTransferListClean" "$dataPathMetric" "$tgftpLogfileName"
		fi
	else
		#  no, so output a usage message
		usageMsg
		exit $_gtransfer_exit_usage
	fi
else
	#  create directory for temp files
	mkdir -p "$__GLOBAL__gtTmpDir"

	# dealias URLs	
	if hash halias &>/dev/null; then
		# remove everything after and including the first "/". As an alias
		# mustn't contain any forward slashes, if an alias is used in the URLs,
		# it's everything from start to the first forward slash.
		_tmpSourceAlias=${gsiftpSourceUrl%%\/*}
		_tmpDestinationAlias=${gsiftpDestinationUrl%%\/*}
		
		_originalGsiftpSourceUrl="$gsiftpSourceUrl"
		_originalGsiftpDestinationUrl="$gsiftpDestinationUrl"
	
		_tmpSourceAliasValue=$( halias --dealias "$_tmpSourceAlias" )
		if [[ $? != 0 ]]; then
			echo "${_program} [${gtInstance}]: Dealiasing failed for source URL!" 1>&2
			exit $_gtransfer_exit_software
		fi
		_tmpDestinationAliasValue=$( halias --dealias "$_tmpDestinationAlias" )
		if [[ $? != 0 ]]; then
			echo "${_program} [${gtInstance}]: Dealiasing failed for destination URL!" 1>&2
			exit $_gtransfer_exit_software
		fi

		# check if the alias value is different from the alias itself
		if [[ "$_tmpSourceAlias" != "$_tmpSourceAliasValue" ]]; then
	
			_tmpSourcePath=${gsiftpSourceUrl#*\/}
			gsiftpSourceUrl="${_tmpSourceAliasValue}/${_tmpSourcePath}"
		
		fi
	
		if [[ "$_tmpDestinationAlias" != "$_tmpDestinationAliasValue" ]]; then
				
			_tmpDestinationPath=${gsiftpDestinationUrl#*\/}
			gsiftpDestinationUrl="${_tmpDestinationAliasValue}/${_tmpDestinationPath}"
		fi
	fi

	# Handle persistent identifiers (PIDs) as source
	if [[ "$gsiftpSourceUrl" =~ 'pid://' ]]; then
		
		if hash irule &>/dev/null; then
			_pid="${gsiftpSourceUrl/pid:\/\/}"
		
			# resolve PID
			_resolvedUrl=$( pids/irodsMicroService/resolvePid "$_pid" )
		
			if [[ $? != 0 ]]; then
				echo "${_program} [${gtInstance}]: Given PID \"$_pid\" could not be resolved. Exiting." 1>&2
				exit $_gtransfer_exit_software
			fi
		
			gsiftpSourceUrl="$_resolvedUrl"
		else
			echo "${_program} [${gtInstance}]: Cannot resolve PID without \"irule\" tool. Exiting" 1>&2
			exit $_gtransfer_exit_software
		fi
	# Handle a list of persistent identifiers (PIDs) as source	
	elif [[ "$gsiftpSourceUrl" =~ 'pidfile://' ]]; then
	
		if hash irule &>/dev/null; then
			_pidFile="${gsiftpSourceUrl/pidfile:\/\/}"
			
			if [[ ! -e "$_pidFile" ]]; then
				echo "${_program} [${gtInstance}]: PID file \"$_pidFile\" cannot be found! Exiting." 1>&2
				exit $_gtransfer_exit_usage
			fi
			
			helperFunctions/echoIfVerbose "${_program} [${gtInstance}]: Resolving PID file..."
			_resolvedPids=$( pids/irodsMicroService/resolvePidFile "$_pidFile" )
			
			if [[ $? -ne 0 ]]; then
				echo "${_program} [${gtInstance}]: At least one PID could not be resolved."
			fi
			
			if [[ -z "$_resolvedPids" ]]; then
				echo "${_program} [${gtInstance}]: PIDs in PID file \"$_pidFile\" could not be resolved! Exiting." 1>&2
				exit $_gtransfer_exit_software
			fi
			
			helperFunctions/echoIfVerbose "${_program} [${gtInstance}]: Building transfer list..."
			gsiftpTransferList=$( pids/irodsMicroService/buildTransferList "$_resolvedPids" "$gsiftpDestinationUrl" )
			
			# exchange source URL specification with transfer list
			# spec
			_modifiedGtCommandLine="${__GLOBAL__gtCommandLine/$gsiftpSourceUrl/ -f $gsiftpTransferList}"
			# remove any source option
			_modifiedGtCommandLine="${_modifiedGtCommandLine/ -s }"
			_modifiedGtCommandLine="${_modifiedGtCommandLine/ --source }"
			# remove destination URL spec
			#_modifiedGtCommandLine="${_modifiedGtCommandLine/$gsiftpDestinationUrl}"
			_modifiedGtCommandLine="${_modifiedGtCommandLine/$_originalGsiftpDestinationUrl}"
			# remove any destination option
			_modifiedGtCommandLine="${_modifiedGtCommandLine/ -d }"
			_modifiedGtCommandLine="${_modifiedGtCommandLine/ --destination }"
			
			# call new gt instance to perform a list transfer
			$_modifiedGtCommandLine
			exit $?
		else
			echo "${_program} [${gtInstance}]: Cannot resolve PIDs without \"irule\" tool. Exiting." 1>&2
			exit $_gtransfer_exit_software
		fi	
	fi

	#                     automatically strips commend lines!
	gsiftpTransferList=$( listTransfer/createTransferList "$gsiftpSourceUrl" "$gsiftpDestinationUrl" )

	# TODO:
	# Check that this does not fail! Because for a case where one wants to
	# transfer two files to /dev/null with multipathing and usage of two
	# paths enabled (i.e. each file uses another path, so it should be
	# basically ok to transfer to /dev/null, because only one file is
	# transferred to /dev/null) the `guc -do [...]` call that creates the
	# transfer list will fail with:
	# ```
	# $ globus-url-copy -do transferlist 'gsiftp://server1/dev/shm/testfiles-mem2mem/1*' gsiftp://server2/dev/null
	#
	# error: Multiple source urls must be transferred to a directory destination url:
	# gsiftp://server2/dev/null
	# $ echo $?
	# 1
	# ```

	if [[ ! -s "$gsiftpTransferList" ]]; then
		helperFunctions/echoIfVerbose "${_program} [${gtInstance}]: Couldn't create transfer list. Exiting." 1>&2
		exit $_gtransfer_exit_software
	fi

	_transferListSource=$( listTransfer/getSourceFromTransferList "$gsiftpTransferList" )
	_transferListDestination=$( listTransfer/getDestinationFromTransferList "$gsiftpTransferList" )
	#_dpath=$( listTransfer/dpathAvailable "$_transferListSource" "$_transferListDestination" )
	_dpath=$( listTransfer/getDpathFile "$_transferListSource" "$_transferListDestination" )

	if [[ $_activateMultipathing -eq 1 ]]; then

		#echo "DEBUG: Multipathing activated!" 1>&2

		#echo "DEBUG: _dpath=\"$_dpath\"" 1>&2

		# create array of metrics
		declare -a _dpathMetricArray
		if [[ "$dataPathMetric" == "all" ]]; then
			_dpathMetricArray=( $( grep '^<path .*metric=' < "$_dpath" | grep -o 'metric="[[:digit:]]*"' | sed -e 's/^metric="//' -e 's/"$//' ) )
		else
			_dpathMetricArray=( $( echo "$dataPathMetric" | tr ',' ' ' ) )
			for _dpathMetric in "${_dpathMetricArray[@]}"; do
				if ! helperFunctions/isValidMetric $_dpath $_dpathMetric; then

					echo "${_program} [${gtInstance}]: Invalid metric value(s) used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
					exit $_gtransfer_exit_usage
				fi
			done
		fi

		multipathing/performTransfer "$gsiftpTransferList" "$_dpath" "$dataPathMetric" "$autoOptimize" "$_verboseOption"

	elif [[ $autoOptimize -eq 1 ]]; then

		if ! helperFunctions/isValidMetric "$_dpath" "$dataPathMetric"; then

			echo "${_program} [${gtInstance}]: Invalid metric value used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
			exit $_gtransfer_exit_usage
		fi

		#  only perform auto-optimization if there are at least
		#+ 100 files in the transfer list. If not perform simple
		#+ list transfer.
		if [[ $( listTransfer/getNumberOfFilesFromTransferList "$gsiftpTransferList" ) -ge 100 ]]; then

			autoOptimization/performTransfer "$gsiftpTransferList"  "$dataPathMetric" "$tgftpLogfileName" "$chunkConfig" "$transferMode"
		else
			# Only perform list transfers from now on
			#rm "$gsiftpTransferList"
			#urlTransfer/transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
			listTransfer/performTransfer "$gsiftpTransferList" "$dataPathMetric" "$tgftpLogfileName"
		fi
	else

		if ! helperFunctions/isValidMetric "$_dpath" "$dataPathMetric"; then

			echo "${_program} [${gtInstance}]: Invalid metric value used! Please check the used dpath \"$_dpath\" for valid metrics." 1>&2
			exit $_gtransfer_exit_usage
		fi

		# Only perform list transfers from now on
		#urlTransfer/transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
		listTransfer/performTransfer "$gsiftpTransferList" "$dataPathMetric" "$tgftpLogfileName"
	fi
fi

#transferData "$gsiftpSourceUrl" "$gsiftpDestinationUrl" "$dataPathMetric" "$tgftpLogfileName"
transferDataReturnValue=$?

#  if transfer was successful, remove dir for temp files
if [[ $transferDataReturnValue -eq 0 && \
      $GT_KEEP_TMP_DIR -ne 1 ]]; then
	rm -rf "$__GLOBAL__gtTmpDir"
fi

#  automatically remove logfiles if needed
if [[ $autoClean == 0 ]]; then
	rm -rf ${tgftpLogfileName/%.log/}*
fi

exit $transferDataReturnValue

