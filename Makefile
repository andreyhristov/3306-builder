ifneq ($(ENVOS),)
  OSVER=$(ENVOS)
else
  OSVER=1804
endif

BOOST_VERSION=67

BST_DOT_VER=1.$(BOOST_VERSION).0
BST_DASH_VER=1_$(BOOST_VERSION)_0
BST_DOWNLOAD_CMD=cd /home/developer/boost && \
		 wget -c https://netix.dl.sourceforge.net/project/boost/boost/$(BST_DOT_VER)/boost_$(BST_DASH_VER).tar.bz2 && \
		 tar jxvf boost_$(BST_DASH_VER).tar.bz2 && \
		 rm boost_$(BST_DASH_VER).tar.bz2


MYSQL_SOURCE_LOCATION=src
CMAKE_CMD=find -name CMakeCache.txt -delete ; \
	  find -name CMakeFiles -exec rm -rf {} \; ; \
	  \
	  CC='' CXX='ccache g++' cmake /home/developer/$(MYSQL_SOURCE_LOCATION)/server \
	  -DWITH_SSL:STRING=system \
	  -DMYSQL_MAINTAINER_MODE:BOOL=ON \
	  -DWITH_DEBUG:BOOL=ON \
	  -DWITH_VALGRIND:BOOL=ON \
	  -DWITH_BOOST=/home/developer/boost/boost_1_$(BOOST_VERSION)_0/

#change this to download something else
TAR_MAJOR_MINOR=8.0
TAR_PATCH=0-dmr
TAR_PREFIX=$(TAR_MAJOR_MINOR).$(TAR_PATCH)
TAR_DIR=mysql-$(TAR_PREFIX)
TAR_EXTENSION=.tar.gz
TAR_FILE=mysql-$(TAR_PREFIX)$(TAR_EXTENSION)


#see docker-compose.yml
DC_INSTANCE_NAME_PREFIX=compiler
DC_INSTANCE_NAME=$(DC_INSTANCE_NAME_PREFIX)$(OSVER)

DOCKER_BUILD_TAG_PREFIX=3306-builder-
DOCKER_BUILD_TAG=$(DOCKER_BUILD_TAG_PREFIX)$(OSVER)


GIT_REMOTE_ORIGIN=https://github.com/mysql/mysql-server.git

CPUS=4

compile:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build/ && make -j$(CPUS)"

test:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build/ && cd mysql-test && ./mtr"
	

boost:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer && $(BST_DOWNLOAD_CMD)"

cmake:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build/ && $(CMAKE_CMD)"

clean:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build && make clean"

ccache_clean:
	docker exec --user developer $(DC_INSTANCE_NAME) sh -c "ccache -C"
	
download:
	cd $(MYSQL_SOURCE_LOCATION) && \
	wget -c https://dev.mysql.com/get/Downloads/MySQL-$(TAR_MAJOR_MINOR)/$(TAR_FILE) && \
	rm server ; \
	tar zxvf $(TAR_FILE) && \
	ln -s $(TAR_DIR) server && \
	rm $(TAR_FILE)

clone_git:
	git clone $(GIT_REMOTE_ORIGIN) && \
	mkdir src && \
	mv mysql-server src/vanilla && \
	cd src && \
	ln -s vanilla server
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-8.0 8.0 && \
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-5.7 5.7 && \
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-5.6 5.6

container_build:
	echo "Building Docker image"
	docker build -f Dockerfile.$(OSVER) . -t $(DOCKER_BUILD_TAG)

bootstrap_download: download container start boost cmake

bootstrap_git: clone_git container_build container_start boost cmake

container_start:
	@mkdir builddir/$(OSVER) ccachedir/$(OSVER); \
	docker run -d \
		--env CCACHE_DIR=/home/developer/ccache \
		-v `pwd`/src:/home/developer/src \
		-v `pwd`/boostdir:/home/developer/boost \
		-v `pwd`/builddir/$(OSVER):/home/developer/build \
		-v `pwd`/ccachedir/$(OSVER):/home/developer/ccache \
		--name $(DC_INSTANCE_NAME) \
		$(DOCKER_BUILD_TAG)	

container_kill:
	docker kill $(DC_INSTANCE_NAME)
	docker rm $(DC_INSTANCE_NAME)

container_shell:
	docker exec -it --privileged --user developer $(DC_INSTANCE_NAME) bash
