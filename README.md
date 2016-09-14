# 3306-builder

## What is 3306-builder

3306-builder is a system for building MySQL (from source tarball or git clone) in a container. This means that you don't need to pollute your host system with libraries and compilers just to be able to compile MySQL from source.

## Which guest systems do 3306-builder support?

Currently 3306-builder supports the following containers:
* Ubuntu 16.04
* Ubuntu 14.04

Adding a new one is pretty easy. Dockerfile.1604 needs to be copied and the packets which are installed for 16.04 need to be installed on the equivalent new platform. For Debian only the FROM: part needs a change.

## How does 3306-builder work?

3306-builder uses Makefile magic. Make is most probably already available on your system. The commands are in the form of __make__ _command__
