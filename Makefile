.PHONY: clean all desktop osx linux pi windows current run

include config.mk

ALLNIMOPTS:=-d:release --opt:size $(NIMOPTS)

ifeq ($(EXECNAME),)
EXECNAME:=$(NAME)
endif

DOCOMPRESS:=$(shell echo $(COMPRESS) | tr A-Z a-z | cut -c1-1)

NIMFILES:=$(wildcard *.nim *.c)

desktop:osx linux windows

all:desktop pi

clean:
	rm -rf target nimcache ${NAME}

osx:target/${EXECNAME}.osx

linux:target/${EXECNAME}.linux

windows:target/${EXECNAME}.64.exe

pi:target/${EXECNAME}.arm.linux target/${EXECNAME}.arm64.linux

current:${NIMFILES}
	nim ${COMPILER} ${ALLNIMOPTS} ${NAME}

target/${EXECNAME}.osx:${NIMFILES}
	mkdir -p target
	nim ${COMPILER} ${ALLNIMOPTS} --passC="-mmacosx-version-min=10.7 -gfull" --passL="-mmacosx-version-min=10.7 -dead_strip" ${NAME}
	strip ${NAME}
	mv ${NAME} target/${EXECNAME}.osx
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.osx ; fi

target/${EXECNAME}.linux:${NIMFILES}
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "nim ${COMPILER} ${ALLNIMOPTS} ${NAME} && strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.linux ; fi

target/${EXECNAME}.arm.linux:${NIMFILES}
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "nim ${COMPILER} ${ALLNIMOPTS} --cpu:arm --os:linux ${NAME} && arm-linux-gnueabi-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.arm.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.arm.linux ; fi

target/${EXECNAME}.arm64.linux:${NIMFILES}
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "nim ${COMPILER} ${ALLNIMOPTS} --cpu:arm64 --os:linux ${NAME} && aarch64-linux-gnu-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.arm64.linux
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.arm64.linux ; fi

target/${EXECNAME}.64.exe:${NIMFILES}
	mkdir -p target
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "nim ${COMPILER} ${ALLNIMOPTS} -d:mingw --cpu:i386  --app:${WINAPP} ${NAME} && i686-w64-mingw32-strip   ${NAME}.exe"
	mv ${NAME}.exe target/${EXECNAME}.32.exe
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.32.exe ; fi
	docker run --rm -v `pwd`:/usr/src/app -w /usr/src/app teras/nimcross bash -c "nim ${COMPILER} ${ALLNIMOPTS} -d:mingw --cpu:amd64 --app:${WINAPP} ${NAME} && x86_64-w64-mingw32-strip ${NAME}.exe"
	mv ${NAME}.exe target/${EXECNAME}.64.exe
	if [ "$(DOCOMPRESS)" = "y" ] ; then upx --best target/${EXECNAME}.64.exe ; fi

run:osx
	./target/${EXECNAME}.osx ${RUNARGS}
