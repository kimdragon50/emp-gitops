FROM baitnami/jenkins:2.277.1-debian-10-r2

ENV JENKINS_UC_DOWNLOAD=http://mirrors.jenkins.io/
ENV JENKINS_UC_DOWNLOAD=https://ftp-chi.osuosl.org/pub/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://ftp.halifax.rwth-aachen.de/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://ftp-nyc.osuosl.org/pub/jenkins
ENV JENKINS_UC_DOWNLOAD=https://ftp.yz.yamagata-u.ac.jp/pub/misc/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://mirror.esuni.jp/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://mirror.gruenehoelle.nl/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins/
ENV JENKINS_UC_DOWNLOAD=https://mirror.xmission.com/jenkins/

# Install Blue Ocean plugin 1.24.3 and all its dependencies
RUN jenkins-plugin-cli --verbose --plugins blueocean:1.24.3