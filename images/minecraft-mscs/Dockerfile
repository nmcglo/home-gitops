FROM ubuntu:22.04

# Dependencies for MSCS found from their website
RUN apt-get update && \
    apt-get install -y sudo openjdk-17-jdk perl libjson-perl libwww-perl liblwp-protocol-https-perl util-linux make wget git rdiff-backup rsync socat iptables && \
    apt-get clean

# Install MSCS
WORKDIR /home/minecraft
RUN git clone https://github.com/MinecraftServerControl/mscs.git
RUN cd mscs && make install

VOLUME ["/opt/mscs"]

WORKDIR /opt/mscs

# Create a default world for the image, accept the eula preemptively
RUN mscs create default && echo "eula=true" > /opt/mscs/worlds/default/eula.txt

# Expose the Minecraft server port
EXPOSE 25565

# start the server and keep container running
CMD ["/bin/bash", "-c", "msctl -p mscs -l /opt/mscs -c /opt/mscs/mscs.defaults start; sleep infinity"]

