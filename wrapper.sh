properties_location=""
tmp_context_dir="/tmp/cw"

# -------- Main functions -------- 

function cw-init() {
	__update_properties_location_or_exit && return

	new_image_name=`cat $properties_location/cw.properties | grep 'IMAGE_NAME' | cut -f2 -d"="`
	if [[ "$IMAGE_NAME" ]] && [[ "`cw-list`" ]]; then
		if [[ "$IMAGE_NAME" != "$new_image_name" ]]; then
			read -n1 -p "There are active containers with image $IMAGE_NAME. Do you want to remove them? (y/n) " confirm
			echo -e "\n" >&2
			if [ $confirm == 'y' ]; then
				echo "Removing old containers."
				cw-delete `cw-list`
			fi
		fi
	fi

	source "$properties_location/cw.properties"

	__build_docker_file
}

function cw-build-step() {
	__exit_if_not_initialized && return

	command="$@"

	if [[ "`cw-list`" ]]; then
		read -n1 -p "There are active containers with image $IMAGE_NAME. This operation will delete them. Do you want to continue? (y/n) " confirm
		echo -e "\n" >&2
		if [ $confirm == 'y' ]; then
			echo "Removing containers."
			cw-delete `cw-list`
		fi
	fi

	echo "$command" >> "$properties_location/provisioning.sh"
	__build_docker_file
}

function cw() {
	__exit_if_not_initialized && return

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
	__exit_if_not_initialized && return

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
	__exit_if_not_initialized && return

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
	__exit_if_not_initialized && return

	docker ps | grep -ve '^CONTAINER ID' | grep -e "[a-z0-9]*\s$IMAGE_NAME\s" | rev | cut -f1 -d' ' | rev
}

function cw-attach() {
	__exit_if_not_initialized && return

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

function __build_docker_file() {
	echo "FROM $FROM
RUN mkdir $MOUNT_DIR
WORKDIR $MOUNT_DIR" > "$properties_location/Dockerfile"

	__init_provisioning_file_if_not_existing
	cat "$properties_location/provisioning.sh" | grep -v -e '^#' >> "$properties_location/Dockerfile"

	! [[ -d "$tmp_context_dir" ]] && mkdir "$tmp_context_dir"
	docker build -f "$properties_location/Dockerfile" "$tmp_context_dir" -t $IMAGE_NAME
	if [[ $? != 0 ]]; then
		echo "Build failed. Reverting."
		sed -i -e '$d' "$properties_location/provisioning.sh"
	fi
	rm -rf "$tmp_context_dir"
	rm "$properties_location/Dockerfile"
}

function __update_properties_location_or_exit() {
	if ! [[ -f "cw.properties" ]]; then
		echo "cw.properties file not found."
		if [[ $properties_location ]]; then
			echo "Keeping the cw.properties in $properties_location"
		fi
		return 0
	fi
	properties_location=`pwd`
	return 1
}

function __init_provisioning_file_if_not_existing() {
	if ! [[ -f "$properties_location/provisioning.sh" ]]; then
		echo "#Insert commands to be executed during docker build
RUN apt-get update -yqq && apt-get upgrade -yqq
RUN apt-get install -yqq command-not-found" >> "$properties_location/provisioning.sh"
	fi
}

function __exit_if_not_initialized() {
	if [[ -z "$properties_location" ]]; then 
		echo "Not initialized. Run cw-init in folder containing \"cw.properties\" file."
		return 0
	fi
	return 1
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