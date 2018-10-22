#/bin/bash

source cw.properties

echo "FROM $FROM" > Dockerfile
echo "RUN mkdir $MOUNT_DIR" >> Dockerfile
echo "WORKDIR $MOUNT_DIR" >> Dockerfile
echo -e "\n#PROVISIONING" >> Dockerfile

cat provisioning.sh | while read line
do
	if [[ "$line" ]]; then
		echo "RUN $line" >> Dockerfile
	fi
done

docker build . -t $IMAGE_NAME