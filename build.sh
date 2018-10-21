#/bin/bash

cat Dockerfile_base > Dockerfile
echo -e "\n\n#PROVISIONING" >> Dockerfile

cat provisioning.sh | while read line
do
	echo $line
	if [[ "$line" ]]; then
		echo "RUN $line" >> Dockerfile
	fi
done

docker build . -t command_wrapper