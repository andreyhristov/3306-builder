BOOST_VERSION=60
BST_DOT_VER=1.$(BOOST_VERSION).0
BST_DASH_VER=1_$(BOOST_VERSION)_0
BST_DOWNLOAD_CMD=cd /home/developer/boost && \
		 wget -c http://netix.dl.sourceforge.net/project/boost/boost/$(BST_DOT_VER)/boost_$(BST_DASH_VER).tar.bz2 && \
		 tar jxvf boost_$(BST_DASH_VER).tar.bz2 && \
		 rm boost_$(BST_DASH_VER).tar.bz2


MYSQL_SOURCE_LOCATION=src
CMAKE_CMD=find -name CMakeCache.txt -delete ; \
	  find -name CMakeFiles -exec rm -rf {} \; ; \
	  \
	  CC='' CXX='ccache g++' cmake /home/developer/$(MYSQL_SOURCE_LOCATION)/mysql-server \
	  -DWITH_SSL:STRING=system \
	  -DMYSQL_MAINTAINER_MODE:BOOL=OFF \
	  -DWITH_DEBUG:BOOL=ON \
	  -DWITH_BOOST=/home/developer/boost/boost_1_$(BOOST_VERSION)_0/

#change this to download something else
TAR_MAJOR_MINOR=8.0
TAR_PATCH=0-dmr
TAR_PREFIX=$(TAR_MAJOR_MINOR).$(TAR_PATCH)
TAR_EXTENSION=.tar.gz
TAR_FILE=mysql-$(TAR_PREFIX)$(TAR_EXTENSION)


#see docker-compose.yml
DC_INSTANCE_NAME=compiler


CPUS=4


compile:
	docker-compose exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build && make -j$(CPUS)"

download_boost:
	docker-compose exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer && $(BST_DOWNLOAD_CMD)"

cmake:
	docker-compose exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build && $(CMAKE_CMD)"


clean:
	docker-compose exec --user developer $(DC_INSTANCE_NAME) sh -c "cd /home/developer/build && make clean"

ccache_clean:
	docker-compose exec --user developer $(DC_INSTANCE_NAME) sh -c "ccache -C"
	
download:
	cd $(MYSQL_SOURCE_LOCATION) && \
	wget -c http://dev.mysql.com/get/Downloads/MySQL-$(TAR_MAJOR_MINOR)/$(TAR_FILE) && \
	rm -rf mysql-server && \
	tar zxvf $(TAR_FILE) && \
	mv $(TAR_PREFIX) mysql-server && \
	rm $(TAR_FILE)

clone_git:
	git clone https://github.com/mysql/mysql-server.git && \
	mv mysql-server src/vanilla && \
	cd src && \
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-8.0 8.0 && \
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-5.7 5.7 && \
	bash /usr/share/doc/git/contrib/workdir/git-new-workdir vanilla ./mysql-5.6 5.6

up:
	docker-compose up -d

kill:
	docker-compose kill
	docker-compose rm --force

stop:
	docker-compose stop
	docker-compose rm --force

pull:
	docker-compose pull

ps:
	docker-compose ps
 
shell:
	docker-compose exec --privileged --user developer $(DC_INSTANCE_NAME) bash

rootshell:
	docker-compose exec --privileged $(DC_INSTANCE_NAME) bash
