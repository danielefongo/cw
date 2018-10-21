FROM bash:rc
COPY provisioning.sh .
RUN bash provisioning.sh

RUN mkdir /pc
WORKDIR /pc