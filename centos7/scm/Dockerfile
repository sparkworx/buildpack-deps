FROM buildpack-deps:centos7-curl

# procps is very common in build systems, and is a reasonably small package
RUN yum install -y \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		\
		procps \
	&& yum clean all
