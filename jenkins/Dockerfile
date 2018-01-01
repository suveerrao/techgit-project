FROM jenkins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
USER root
RUN curl -fsSL https://get.docker.com/ | sh
RUN apt-get update && apt-get install -y sudo && usermod -a -G docker jenkins
COPY sudoers /etc/sudoers
USER jenkins