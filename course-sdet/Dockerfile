FROM ubuntu:12.04
MAINTAINER junhee cho <junhee.cho@lge.com>

RUN apt-get update

# Install basic packages
RUN apt-get -y install curl git gcc g++ libc6 libc6-dev-i386 ocaml wget m4 make autoconf unzip zip

# add data files
ADD ./data /course-data
ADD ./exercise /course-sdet

# install
RUN cd /course-data && ./install.sh
ENV PATH /course-data/crest-0.1.2/bin:$PATH
RUN echo $PATH
RUN which run_crest
