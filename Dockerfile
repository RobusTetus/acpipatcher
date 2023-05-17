FROM fedora
RUN mkdir acpipatcher
WORKDIR acpipatcher
RUN dnf install -y acpica-tools hexdump 7z unzip
VOLUME tables 
COPY . .
CMD ["./script.sh"]
