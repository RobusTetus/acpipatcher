FROM fedora
RUN mkdir acpipatcher
WORKDIR acpipatcher
RUN dnf install -y \
acpica-tools \
p7zip \
unzip \
wget \
util-linux \
p7zip-plugins
COPY . .
RUN dnf clean all
ENTRYPOINT [ "./script.sh" ]
