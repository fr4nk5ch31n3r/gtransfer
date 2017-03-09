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

This product includes software developed by members of the DEISA project
www.deisa.org. DEISA is an EU FP7 integrated infrastructure initiative under
contract number RI-222919.

COPYRIGHT

gtools_complete_urls()
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

	getPathFromAliasUrl()
	{
		local url="$1"
		
		# if there's currentl only the alias, assume "/"
		if ! echo "$url" | grep "/" &>/dev/null; then
			echo "/"
			return
		fi
		
		local path=${url#*/}
		
		#  strip any file portion from path
		#path=${path%/*}
		# add leading '/'
                path="/$path"
		#  strip any file portion from path
		path=$(echo $path | grep -o '/.*/')
		
		#if [[ "$path" != "" ]]; then
		#	echo "/$path/"
		#else
		#	echo "/"
		#fi
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

	#  defuse ":" in completions, as the ":" implies specific readline
	#+ behaviour.
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
	#  also defuse "@" (used when usernames are provided in URLs)
	COMP_WORDBREAKS=${COMP_WORDBREAKS//@}

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	if hash globus-url-copy &>/dev/null; then
		#  complete remote paths
		if echo "$cur" | grep '^gsiftp://.*:.*' &>/dev/null; then

			userhost=$( getURLWithoutPath "${cur}" )
			#echo -e "\n$userhost" 1>&2
			userpath=$( getPathFromURL "${cur}" )
			#echo "$userpath" 1>&2

			local remote_paths=( $( globus-url-copy -list "${userhost}${userpath}*" | sed -e 's/^\ *//' -e 1d ) )

			local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
		
			COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
			return 0
		
		elif echo "$cur" | grep '^ftp://.*:.*' &>/dev/null; then
	
			userhost=$( getURLWithoutPath "${cur}" )
			userpath=$( getPathFromURL "${cur}" )
		
			local remote_paths=( $( globus-url-copy -list "${userhost}${userpath}*" | sed -e 's/^\ *//' -e 1d ) )
		
			local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${userhost}${userpath}${path}; done )
		
			COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
			return 0
		fi

		if hash halias &>/dev/null; then
		
			alias="${cur%%/*}" ## remove path
			user="${alias%%@*}"
			alias="${alias#*@}" ## remove "user@"
		
			if halias --is-alias "$alias" &>/dev/null; then						
	
				userhost=$( halias --dealias "$alias" )

				if [[ "$user" != "$alias" ]]; then

					userhost=${userhost/:\/\//:\/\/$user@}
				fi
				#echo -e "\n$userhost A$alias U$user" 1>&2
				userpath=$( getPathFromAliasUrl "$cur" )
				#echo "$userpath" 1>&2
		
				local remote_paths=( $( globus-url-copy -list "${userhost}${userpath}*" | sed -e 's/^\ *//' -e 1d ) )
		
				if [[ "$user" != "$alias" ]]; then
					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${user}@${alias}${userpath}${path}; done )
				else
					local remote_urls=$( for path in "${remote_paths[@]}"; do echo ${alias}${userpath}${path}; done )
				fi
			
				COMPREPLY=( $(compgen -W "${remote_urls}" -- ${cur}) )
				return 0
			fi
		fi
	fi

	#  only complete source URL host parts if dpath is available
	if hash dpath &>/dev/null; then
		#  complete source URL host parts
		local sites=$( dpath --list-sources )
	else
		local sites=""
	fi
	
	if hash halias &>/dev/null; then
		local aliases=$( halias --list )
	else
		local aliases=""
	fi
	
	if [[ "$sites" != "" && "$aliases" != "" ]]; then
		COMPREPLY=( $(compgen -W "${sites} ${aliases}" -- ${cur}) )
	elif [[ "$sites" != "" ]]; then
		COMPREPLY=( $(compgen -W "${sites}" -- ${cur}) )
	elif [[ "$aliases" != "" ]]; then
		COMPREPLY=( $(compgen -W "${aliases}" -- ${cur}) )
	fi

	return 0
}


gtools_complete_general_options()
{
	local cur prev opts

	#  defuse ":" in completions, as the ":" implies specific readline
	#+ behaviour.
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
	#  also defuse "@" (used when usernames are provided in URLs)
	COMP_WORDBREAKS=${COMP_WORDBREAKS//@}

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	COMPREPLY=( $( compgen -W '--help -h --version -V' -- "$cur" ) )
        COMPREPLY=( "${COMPREPLY[@]/%/ }" )
        return 0
}


gtools_complete_functions()
{
	local cur prev opts

	#  defuse ":" in completions, as the ":" implies specific readline
	#+ behaviour.
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
	#  also defuse "@" (used when usernames are provided in URLs)
	COMP_WORDBREAKS=${COMP_WORDBREAKS//@}

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	COMPREPLY=( $( compgen -W "gcat gls gmkdir gmv grm" -- ${cur} ) )
	return 0
}


_gtools()
{
	local cur prev opts

	#  defuse ":" in completions, as the ":" implies specific readline
	#+ behaviour.
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
	#  also defuse "@" (used when usernames are provided in URLs)
	COMP_WORDBREAKS=${COMP_WORDBREAKS//@}

	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	#echo "${#COMP_WORDS[@]}" 1>&2

	if [[ $( basename $prev) == "gtools" ]]; then

		gtools_complete_functions
		return 0
	fi

	if [[ $( basename $prev ) == "gcat" || \
	      $( basename $prev ) == "gls" || \
	      $( basename $prev ) == "gmkdir" || \
	      $( basename $prev ) == "grm" ]]; then

		case $cur in
		    -*)
		        gtools_complete_general_options
		        return 0
		        ;;
		    *)
		        #+ pass through
		        ;;
		esac

		gtools_complete_urls
		return 0

	elif [[ $( basename ${COMP_WORDS[0]} ) == "gmv" ]]; then

		case $cur in
		    -*)
		        gtools_complete_general_options
		        return 0
		        ;;
		    *)
		        #+ pass through
		        ;;
		esac

		if [[ ${#COMP_WORDS[@]} -le 3 ]]; then

			gtools_complete_urls
			return 0
		fi

	elif [[ $( basename ${COMP_WORDS[1]} ) == "gmv" ]]; then

		case $cur in
		    -*)
		        gtools_complete_general_options
		        return 0
		        ;;
		    *)
		        #+ pass through
		        ;;
		esac

		if [[ ${#COMP_WORDS[@]} -le 4 ]]; then

			gtools_complete_urls
			return 0
		fi
	fi	

	return 0
}

complete -o nospace -F _gtools gtools gcat gls gmkdir gmv grm

