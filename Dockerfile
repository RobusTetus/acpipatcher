FROM ubuntu:latest
RUN mkdir acpipatcher
WORKDIR acpipatcher
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
acpica-tools \
p7zip-full \
unzip \
wget \
curl \
xxd
COPY . .
RUN apt-get clean all
