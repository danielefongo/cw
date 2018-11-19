source wrapper.sh

function cw() {
	subcommand=$1
    shift
    valid_command=`declare -F __cw_$subcommand`
    if [[ $valid_command ]]; then
    	__cw_$subcommand $@
    else
		echo -e "Invalid subcommand.\nRun \"cw help\" to show the man page."
    fi
}

# -------- Autocompletion --------

cw=`declare -F | grep ' __cw_' | rev | cut -f1 -d'_' | rev`

_dothis_completions()
{
	if [ "${#COMP_WORDS[@]}" == "2" ]; then
	suggestions=($(compgen -W "$cw" -- "${COMP_WORDS[1]}"))
	elif [ "${#COMP_WORDS[@]}" == "3" ]; then
		subcommand=${COMP_WORDS[1]}

		if [[ -z "$properties_location" ]]; then
			return
		fi
		if [[ $subcommand == "attach" ]]; then
			suggestions=($(compgen -W "`__cw_list`" -- "${COMP_WORDS[2]}"))
		elif [[ $subcommand == "delete" ]]; then
			suggestions=($(compgen -W "`__cw_list`" -- "${COMP_WORDS[2]}"))
		else
			return
		fi
	else
		return
	fi
	COMPREPLY=("${suggestions[@]}")
}

complete -F _dothis_completions cw