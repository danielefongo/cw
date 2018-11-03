source cw.properties

# -------- Main functions -------- 

function cw() {
	command="eval \"$@\""
	command=`echo "$command" | sed 's/cw //'`;
	id=`__random_container_id`
	__create_docker_net
	docker run --rm --name $id \
		-v `pwd`:$MOUNT_DIR -v $EXTERNAL_USER_HOME:/root \
		--network $IMAGE_NAME \
		-it $IMAGE_NAME \
		sh -c "$command"
	__delete_docker_net
}

function cw-durable() {
	name=$1
	if [[ "$name" ]] && [[ -z `docker ps | grep $name` ]]; then
		__create_docker_net
		docker run -d --name $name \
		-v `pwd`:$MOUNT_DIR -v $EXTERNAL_USER_HOME:/root \
		--network $IMAGE_NAME \
		-i $IMAGE_NAME 1>/dev/null
		echo "Container $name created. Use \"cw-attach $name\" to attach a shell."
	fi
}

function cw-delete() {
	for name in $@
	do
		if [[ "$name" ]] && [[ `docker ps | grep $name` ]]; then
			docker rm -f $name 1>/dev/null
			echo "Container $name deleted."
		fi
	done
	__delete_docker_net
}

function cw-list() {
	docker ps | grep -ve '^CONTAINER ID' | grep -e "[a-z0-9]*\s$IMAGE_NAME\s" | rev | cut -f1 -d' ' | rev
}

function cw-attach() {
	name=$1
	if [[ "$name" ]] && [[ `docker ps | grep $name` ]]; then
		docker exec -it "$name" sh
	fi
}

# -------- Util functions -------- 

function __random_container_id() {
	echo "cw_"$((1 + RANDOM % 1000))
}

function __create_docker_net() {
	if ! [[ `docker network ls | grep -e "[a-z0-9]*\s$IMAGE_NAME\s"` ]]; then
		docker network create $IMAGE_NAME 1>/dev/null
	fi
}

function __delete_docker_net() {
	if [[ -z "`cw-list`" ]]; then
		docker network rm $IMAGE_NAME 1>/dev/null
	fi
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