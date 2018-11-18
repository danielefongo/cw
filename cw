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
