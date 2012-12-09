_gtransfer() 
{
	########################################################################
	#  HELPER FUNCTIONS ####################################################
	########################################################################
	getPathFromURL()
	{
		#  determines the path portion from the URL:
		#
		#  gsiftp://venus.milkyway.universe:2811(/path/to/)file
		#
		#  usage:
		#+ getPathFromURL "URL"

		local URL="$1"

		#local path=$(echo "$URL" | sed -e "s|$( getURLWithoutPath $URL )||")
		#  local path?
		if echo $URL | grep "^.*://" &>/dev/null; then
			#  no
			local tmp=$( echo "$URL" | cut -d '/' -f '4-' )
			#  add leading '/'
			tmp="/$tmp"
		else
			#  yes
			tmp=$URL
		fi

		#  strip any file portion from path
		path=$(echo $tmp | grep -o '/.*/')
		if [[ $path == "" ]]; then
			path="/"
		fi	

		echo "$path"
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
	########################################################################


	local cur prev opts

	#  defuse ":" in completions, as the ":" implies specifc readline
	#+ behaviour.
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
	#  also defuse "@" (used when usernames are provides in URLs)
	COMP_WORDBREAKS=${COMP_WORDBREAKS//@}

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	#  all available gtransfer options/switches/parameters	
	opts="--source -s --destination -d --help --verbose -v --version -V --metric -m --logfile -l --auto-clean -a --configfile --"

	#  parameter completion
	case "${prev}" in
	
		--source|-s)
			#  only complete remote paths if globus-url-copy is
			#+ available
			if hash globus-url-copy &>/dev/null; then
				#  complete remote paths
				if echo "$cur" | grep '^gsiftp://.*:.*/.*' &>/dev/null; then
			
					userhost=$( getURLWithoutPath "${cur}" )
			
					userpath=$( getPathFromURL "${cur}" )

					local remote_paths=( $( globus-url-copy -list "$cur*" | sed -e 's/^\ *//' -e 1d ) )

					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
					COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
					return 0
                		elif echo "$cur" | grep '^ftp://.*:.*/.*' &>/dev/null; then
					userhost=$( getURLWithoutPath "${cur}" )
					userpath=$( getPathFromURL "${cur}" )
					local remote_paths=( $( globus-url-copy -list "$cur*" | sed -e 's/^\ *//' -e 1d ) )
					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
					COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
					return 0
				fi
			fi

			#  only complete destination URLs if dpath is available
			if hash dpath &>/dev/null; then
				#  complete source URLs
				local sites=$( dpath --list-sources )
				COMPREPLY=( $(compgen -W "${sites}" -- ${cur}) )
				return 0
			fi
			;;

		--destination|-d)
			#  only complete remote paths if globus-url-copy is
			#+ available
			if hash globus-url-copy &>/dev/null; then
				#  complete remote paths
				if echo "$cur" | grep '^gsiftp://.*:.*/.*' &>/dev/null; then
					userhost=$( getURLWithoutPath "${cur}" )
					userpath=$( getPathFromURL "${cur}" )
					local remote_paths=( $( globus-url-copy -list "$cur*" | sed -e 's/^\ *//' -e 1d ) )
					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
					COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
					return 0
                		elif echo "$cur" | grep '^ftp://.*:.*/.*' &>/dev/null; then
					userhost=$( getURLWithoutPath "${cur}" )
					userpath=$( getPathFromURL "${cur}" )
					local remote_paths=( $( globus-url-copy -list "$cur*" | sed -e 's/^\ *//' -e 1d ) )
					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
					COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
					return 0
				fi
			fi			

			#  only complete destination URLs if dpath is available
			if hash dpath &>/dev/null; then
				#  complete destination URLs
				local sites=$( dpath --list-destinations )
				COMPREPLY=( $(compgen -W "${sites}" -- ${cur}) )
				return 0
			fi
			;;

		--metric|-m)
			#  propose metrics 0 to 3
			local metrics=$(for x in 0 1 2 3; do echo $x; done )
			COMPREPLY=( $(compgen -W "${metrics}" -- ${cur}) )
			return 0
			;;

		*)
			;;
	esac

	#  complete possible gtransfer options/switches/parameters
	COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	return 0

}
complete -o nospace -F _gtransfer gtransfer gt

