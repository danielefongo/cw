source cw.properties

__random_container_id() {
	echo "cw_"$((1 + RANDOM % 1000))
}

function cw() {
	command="eval \"$@\""
	command=`echo "$command" | sed 's/cw //'`;
	id=`__random_container_id`
	docker run --rm --name $id \
		-v `pwd`:$MOUNT_DIR -v $EXTERNAL_USER_HOME:/root \
		-it $IMAGE_NAME \
		bash -c "$command"
}

postexec() {
if [[ $? -eq 127 ]]; then
	echo "Redirecting to docker container.."
	cw "$wrapper_last_command"
fi
}

preexec_invoke_exec () {
    [ -n "$COMP_LINE" ] && return
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return
    local this_command=`HISTTIMEFORMAT= history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//"`;
    wrapper_last_command="$this_command"
}

trap 'preexec_invoke_exec' DEBUG
PROMPT_COMMAND=postexec