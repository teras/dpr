.PHONY: clean all desktop osx linux pi windows current install run preosx prelinux prepi prewindows

# needs to be defined before include
default:current

include config.mk

DEST:=~/Works/System/arch

ALLNIMOPTS=-d:release -d:VERSION=$(VERSION) --opt:size $(NIMOPTS)

ifeq ($(EXECNAME),)
EXECNAME:=$(NAME)
endif

ifeq ($(VERSION),)
VERSION:=0.1
endif

ifeq ($(COMPILER),)
COMPILER:=c
endif

ifeq ($(WINAPP),)
WINAPP:=console
endif

ifneq ($(NIMBLE),)
NIMBLE:=nimble -y install $(NIMBLE);
endif

ifneq ($(NIMVER),)
NIMVER:=choosenim $(NIMVER);
endif

DOCOMPRESS:=$(shell echo $(COMPRESS) | tr A-Z a-z | cut -c1-1)

BUILDDEP:=$(wildcard *.nim *.c Makefile config.mk)

current:target/${EXECNAME}

all:desktop pi

desktop:osx linux windows

pi:target/${EXECNAME}.arm64.linux

osx:target/${EXECNAME}.osx

linux:target/${EXECNAME}.linux

windows:target/${EXECNAME}.64.exe

clean:
	rm -rf target nimcache ${NAME} ${NAME}.exe

target/${EXECNAME}:${BUILDDEP}
	${NIMVER} nim ${COMPILER} ${ALLNIMOPTS} ${NAME}
	mkdir -p target
	mv ${NAME} target/${EXECNAME}
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME} ; fi

target/${EXECNAME}.osx:${BUILDDEP} preosx
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} --os:macosx --passC:'-mmacosx-version-min=10.7 -gfull' --passL:'-mmacosx-version-min=10.7 -dead_strip' ${NAME} && x86_64-apple-darwin19-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.osx
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.osx ; fi

target/${EXECNAME}.linux:${BUILDDEP} prelinux
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} ${NAME} && strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.linux ; fi

target/${EXECNAME}.arm64.linux:${BUILDDEP} prepi
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} --cpu:arm --os:linux ${NAME} && arm-linux-gnueabi-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.arm.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.arm.linux ; fi
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} --cpu:arm64 --os:linux ${NAME} && aarch64-linux-gnu-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.arm64.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.arm64.linux ; fi

target/${EXECNAME}.64.exe:${BUILDDEP} prewindows
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} -d:mingw --cpu:i386  --app:${WINAPP} ${NAME} && i686-w64-mingw32-strip   ${NAME}.exe"
	mv ${NAME}.exe target/${EXECNAME}.32.exe
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.32.exe ; fi
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "${NIMVER} ${NIMBLE} nim ${COMPILER} ${ALLNIMOPTS} -d:mingw --cpu:amd64 --app:${WINAPP} ${NAME} && x86_64-w64-mingw32-strip ${NAME}.exe"
	mv ${NAME}.exe target/${EXECNAME}.64.exe
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.64.exe ; fi

install:all
	mkdir -p ${DEST}/darwin-x86_64/ && cp target/${EXECNAME}.osx ${DEST}/darwin-x86_64/${EXECNAME}
	mkdir -p ${DEST}/linux-x86_64/ && cp target/${EXECNAME}.linux ${DEST}/linux-x86_64/${EXECNAME}
	mkdir -p ${DEST}/linux-arm && cp target/${EXECNAME}.arm.linux ${DEST}/linux-arm/${EXECNAME}
	mkdir -p ${DEST}/linux-arm64 && cp target/${EXECNAME}.arm64.linux ${DEST}/linux-arm64/${EXECNAME}
	mkdir -p ${DEST}/windows-x86_64 && cp target/${EXECNAME}.64.exe ${DEST}/windows-x86_64/${EXECNAME}.exe
	mkdir -p ${DEST}/windows-i686 && cp target/${EXECNAME}.32.exe ${DEST}/windows-i686/${EXECNAME}.exe

run:current
	./target/${EXECNAME} ${RUNARGS}
