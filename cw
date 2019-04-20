cw_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$cw_dir/wrapper.sh"

function cw() {
	subcommand=$1
    shift
    valid_command=`declare -f __cw_$subcommand`
    if [[ $valid_command ]]; then
    	__cw_$subcommand $@
    else
		echo -e "Invalid subcommand.\nRun \"cw help\" to show the man page."
    fi
}

shell=`ps -p $$ | awk '{print $NF}' | tail -1`

if [[ "$shell" =~ "zsh" ]]; then
  source $cw_dir/complete.zsh
else
  source $cw_dir/complete.sh
fi
