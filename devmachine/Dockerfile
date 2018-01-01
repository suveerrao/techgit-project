FROM centos:7
RUN yum -y update && \
    yum -y install which git 
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && \
    python get-pip.py
RUN pip install --allow-all-external RBTools