.PHONY: clean all desktop posix mac macintel macarm linux linux32 linux64 arm arm32 arm64 windows win32 win64 local install install-only run docker help


# needs to be defined before include
default:help

include config.mk

DEST:=~/Works/System/bin/arch

ifeq ($(shell which nim 2>/dev/null),)
LOCALNIM=~/.nimble/bin/nim
else
LOCALNIM=$(shell which nim)
endif

ifeq ($(OPTIMIZE),)
OPTIMIZE=size
endif

GENERICOPTS=-d:VERSION=$(VERSION) $(NIMOPTS) --opt:$(OPTIMIZE)

ifeq ($(DEBUG),true)
BASENIMOPTS=$(GENERICOPTS)
else
ifeq ($(DEBUG),full)
BASENIMOPTS=$(GENERICOPTS) -d:debug --debuginfo --linedir:on -d:nimDebugDlOpen
else
ifeq ($(DEBUG),unsafe)
BASENIMOPTS=$(GENERICOPTS) -d:release -d:strip -d:danger
else
BASENIMOPTS=$(GENERICOPTS) -d:release -d:strip
endif
endif
endif

ifeq ($(EXECNAME),)
EXECNAME:=$(NAME)
endif

ifeq ($(VERSION),)
VERSION:=0.1
endif

ifeq ($(COMPILER),)
COMPILER:=c
endif
ifeq ($(COMPILERMAC),)
COMPILERMAC:=$(COMPILER)
endif
ifeq ($(COMPILERLINUX),)
COMPILERLINUX:=$(COMPILER)
endif
ifeq ($(COMPILERWIN),)
COMPILERWIN:=$(COMPILER)
endif
ifeq ($(COMPILERSPI),)
COMPILERSPI:=$(COMPILERLINUX)
endif

ifeq ($(WINAPP),)
WINAPP:=console
endif

ifeq ($(ALLTARGETS),)
ALLTARGETS:=desktop arm linux32
endif

ifeq ($(DOCKER),)
DOCKER:=docker
endif

ifneq ($(NIMBLE),)
NIMBLE:=nimble refresh ; nimble -y install $(NIMBLE);
CONTAINER:=teras/nimcross:${NAME}
CONTAINER32:=teras/nimcross32:${NAME}
CONTAINERMAC:=teras/nimcrossmac:${NAME}
else
CONTAINER:=teras/nimcross
CONTAINER32:=teras/nimcross32
CONTAINERMAC:=teras/nimcrossmac
endif
TEMPCONT:=.temp_dockerfile
SRCCONTFILES:=$(shell for entry in $(SRCONTX); do [ -f "$$entry" ] && echo $$entry; done)
SRCCONTDIRS:=$(shell for entry in $(SRCONTX); do [ -d "$$entry" ] && echo $$entry; done)

ifneq ($(NIMVER),)
NIMVER:=choosenim $(NIMVER);
endif

DOCOMPRESS:=$(shell echo $(COMPRESS) | tr A-Z a-z | cut -c1-1)

TYPEARG:=$(shell echo $(TYPE) | tr A-Z a-z | cut -c1-1)
ifeq ($(TYPEARG),l)
TARGETEXT=dll
else
TARGETEXT=exe
endif

BUILDDEP:=$(wildcard *.nim *.c *.m Makefile config.mk)

localinit:	## Initialize local nimble environment
	$(NIMVER) ${NIMBLE}

local:target/${EXECNAME}	## Create a binary based on locally installed nim compilers

all:$(ALLTARGETS)	## Target all platforms. The actual platforms are stored in configuration variable $ALLTARGETS

desktop:mac linux windows	## Create only desktop platforms. These are macOS, Linux and Windows

posix:mac linux arm 	## Create only POSIX-compatible platforms. These are macOS, Linux and Linux on ARM

arm:arm32 arm64 	## Create only ARM-related targets. These are Linux ARM 32 and Linux ARM 64

arm64:target/${EXECNAME}.aarch64.linux	## Create only Linux ARM 32 target

arm32:target/${EXECNAME}.arm.linux	## Create only Linux ARM 64 target

mac:target/${EXECNAME}.mac		## Create only macOS targets. These are fat macOS ARM 64 and Intel 64

macintel:target/${EXECNAME}.macintel	## Create only macOS Intel 64 target

macarm:target/${EXECNAME}.macarm	## Create only macOS ARM 64 target

linux:linux64	## Create only Linux Intel target. Currently only 64 bit is produced

linux64:target/${EXECNAME}.linux	## Create only Linux Intel (64) target

linux32:target/${EXECNAME}.linux32	## Create only Linux Intel (32) target

windows:win32 win64	 ## Create Windows target, both 32 and 64 bit

win32:target/${EXECNAME}.32.${TARGETEXT}	 ## Create Windows 32 bit target

win64:target/${EXECNAME}.64.${TARGETEXT}	 ## Create Windows 32 bit target

js:target/${EXECNAME}.js  ## Create JavaScript target

clean:	## Clean up project files
	rm -rf target docker.tmp nimcache ${CLEAN}

help:	## Show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

helpconfig:	## Show config.mk options
	@echo 'Required:'
	@echo '    NAME        The application name'
	@echo 'Recommended:'
	@echo '    VERSION     The application version'
	@echo 'Optional:'
	@echo '    ALLTARGETS The actual targets that will be built when the "all" target is selected, defaults to [desktop, arm]'
	@echo '    COMPILER*  The nim compiler to use. * could be empty (all platforms), LINUX (Linux), WIN (Windows), MAC (macOS), PI (Raspberry Pi). Defaults to "c"'
	@echo '    COMPRESS   If the final application should be compressed by upx or not, boolean value, false by default'
	@echo '    DOCKER     The docker command to use, "docker" by default. If you want to use podman, then set it to "podman"'
	@echo '    DEBUG      Use debug build, have release build by default. Valid values: [release, debug, full, unsafe]'
	@echo '    EXECNAME   The executable name, $$NAME by default'
	@echo '    HELP*	  The help message to show when "make help" is called. * could only be LINUX (Linux), MAC (macOS), WIN (Windows), PI (Raspberry Pi). Defaults to empty'
	@echo '    NIMBLE     A list of extra nimble packed needed. If required, then podman/docker target should be called in advance'
	@echo '    NIMOPTS*   Extra nim compiler options. * could be empty (all platforms), LINUX (Linux), WIN (Windows), MAC (macOS), PI (Raspberry Pi)'
	@echo '    OPTIMIZE   The level of optimization. Default is none. Valid values: [none, speed, size]'
	@echo '    RUNARGS    The run arguments when "run" make target is used'
	@echo '    SRCONTX    When creating a source container, this is a space separated list of extra files/folders to put inside the container'
	@echo '    TYPE       The type of the application, defaults to dynamically linked file. Valid values: [dynamic, static, library]'
	@echo '    WINAPP     Type of windows application, valid values [gui,console], "console" by default'

docker:	 ## If required, create specific docker/podman containers to aid compiling this project. Note the DOCKER property in config.mk
	@if [ "${NIMBLE}" != "" ] ; then \
		rm -rf docker.tmp && \
		mkdir docker.tmp && \
		echo >docker.tmp/Dockerfile "FROM teras/nimcross" && \
		echo >>docker.tmp/Dockerfile "RUN ${NIMBLE}" && \
		cd docker.tmp ; $(DOCKER) build -t ${CONTAINER} --no-cache . && cd .. &&\
		rm -rf docker.tmp ; \
        mkdir docker.tmp && \
        echo >docker.tmp/Dockerfile "FROM teras/nimcross32" && \
        echo >>docker.tmp/Dockerfile "RUN ${NIMBLE}" && \
        cd docker.tmp ; $(DOCKER) build -t ${CONTAINER32} --no-cache . && cd .. &&\
        rm -rf docker.tmp ; \
        mkdir docker.tmp && \
        echo >docker.tmp/Dockerfile "FROM teras/nimcrossmac" && \
        echo >>docker.tmp/Dockerfile "RUN ${NIMBLE}" && \
        cd docker.tmp ; $(DOCKER) build -t ${CONTAINERMAC} --no-cache . && cd ..&&\
        rm -rf docker.tmp ; \
	fi

srccontainer:${BUILDDEP} ## Create source containers (with this project source files)
	echo HELLO: $(SRCCONTDIRS)
	echo -e "ARG BASE_IMAGE\nFROM \$$BASE_IMAGE \nCOPY ${SRCCONTFILES} *.nim /root/" >$(TEMPCONT)
	for entry in ${SRCCONTDIRS}; do echo COPY $$entry /root/$$entry/ >>$(TEMPCONT); done
	$(DOCKER) build -t ${CONTAINER}-src -f $(TEMPCONT) --build-arg BASE_IMAGE=${CONTAINER} .
	$(DOCKER) build -t ${CONTAINER32}-src -f $(TEMPCONT) --build-arg BASE_IMAGE=${CONTAINER32} .
	$(DOCKER) build -t ${CONTAINERMAC}-src -f $(TEMPCONT) --build-arg BASE_IMAGE=${CONTAINERMAC} .
	rm $(TEMPCONT)

srcpush:srccontainer	## Create and push source containers.
	$(DOCKER) push ${CONTAINER}-src
	$(DOCKER) push ${CONTAINER32}-src
	$(DOCKER) push ${CONTAINERMAC}-src

target/${EXECNAME}.macintel:${BUILDDEP}
	@printf "$(HELPMAC)"
	@echo "** WARNING ** static binaries & libraries not supported  for macOS platform"
	mkdir -p target
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINERMAC} bash -c "$(NIMVER) nim $(COMPILERMAC) $(BASENIMOPTS) ${NIMOPTSMAC} --os:macosx --cpu:amd64 --passC:'-mmacosx-version-min=10.7 -gfull' --passL:'-mmacosx-version-min=10.7 -dead_strip' ${NAME} && x86_64-apple-darwin22.2-strip ${NAME}"
	mv ${NAME} target/${EXECNAME}.macintel
	# if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${EXECNAME}.macintel ; fi # UPX is broken under macOS right now

target/${EXECNAME}.macarm:${BUILDDEP}
	@printf "$(HELPMAC)"
	@echo "** WARNING ** static binaries & libraries not supported  for macOS platform"
	mkdir -p target
	# Stripping is also broken
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINERMAC} bash -c "$(NIMVER) nim $(COMPILERMAC) $(BASENIMOPTS) ${NIMOPTSMAC} --os:macosx --cpu:arm64 --passC:'-mmacosx-version-min=10.7 -gfull' --passL:'-mmacosx-version-min=10.7 -dead_strip' ${NAME}"
	mv ${NAME} target/${EXECNAME}.macarm
	# if [ "$(DOCOMPRESS)" = "t" ] ; then $(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINERMAC} /usr/local/bin/upx --best ${EXECNAME} ; fi

target/${EXECNAME}.mac:target/${EXECNAME}.macintel target/${EXECNAME}.macarm
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINERMAC} bash -c "lipo -create target/${NAME}.macarm target/${NAME}.macintel -output target/${NAME}.mac "

target/${EXECNAME}:${BUILDDEP}
	@printf "$(HELPLINUX)"
	mkdir -p target
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(NIMVER) ${LOCALNIM} $(COMPILERLINUX) $(BASENIMOPTS) $(NIMOPTSLINUX) ${EXTRA} ${TYPEPARAM} -d:lto --outdir:./target ${NAME}

target/${EXECNAME}.linux:${BUILDDEP}
	@printf "$(HELPLINUX)"
	mkdir -p target
	$(eval CPREF:=/cross/x86_64-linux-musl-cross/bin/x86_64-linux-musl-)
	$(eval EXTRA:=$(NIMOPTSLINUX) -d:lto)
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=lib$(NAME).linux.so), $(eval OUT=$(NAME).linux))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim $(COMPILERLINUX) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best ./target/${OUT} ; fi

target/${EXECNAME}.linux32:${BUILDDEP}
	@printf "$(HELPLINUX)"
	mkdir -p target
	$(eval CPREF:=/cross/i686-linux-musl-cross/bin/i686-linux-musl-)
	$(eval EXTRA:=$(NIMOPTSLINUX) -d:lto --cpu:i386 --passC:-m32 --passL:-m32 --gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc)
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=lib$(NAME).32.linux), $(eval OUT=$(NAME).32.linux))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER32} bash -c "$(NIMVER) nim $(COMPILERLINUX) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${OUT} ; fi

target/${EXECNAME}.arm.linux:${BUILDDEP}
	@printf "$(HELPSPI)"
	mkdir -p target
	$(eval CPREF:=/cross/armel-linux-musleabihf-cross/bin/armel-linux-musleabihf-)
	$(eval EXTRA:=$(NIMOPTSPI) -d:lto --cpu:arm --os:linux)
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=lib$(NAME).arm.linux.so), $(eval OUT=$(NAME).arm.linux))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim $(COMPILERPI) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${OUT} ; fi

target/${EXECNAME}.aarch64.linux:${BUILDDEP}
	@printf "$(HELPSPI)"
	mkdir -p target
	$(eval CPREF:=/cross/aarch64-linux-musl-cross/bin/aarch64-linux-musl-)
	$(eval EXTRA:=$(NIMOPTSPI) -d:lto --cpu:arm64 --os:linux)
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=lib$(NAME).aarch64.linux.so), $(eval OUT=$(NAME).aarch64.linux))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim $(COMPILERPI) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${OUT} ; fi

target/${EXECNAME}.32.${TARGETEXT}:${BUILDDEP}
	@printf "$(HELPWIN)"
	mkdir -p target
	$(eval CPREF:=/cross/i686-w64-mingw32-cross/bin/i686-w64-mingw32-)
	$(eval EXTRA:=$(NIMOPTSWIN) -d:lto -d:mingw --cpu:i386 --app:$(WINAPP))
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=$(NAME).32.dll), $(eval OUT=$(NAME).32.exe))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim $(COMPILERWIN) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${OUT} ; fi

target/${EXECNAME}.64.${TARGETEXT}:${BUILDDEP}
	@printf "$(HELPWIN)"
	mkdir -p target
	$(eval CPREF:=/cross/x86_64-w64-mingw32-cross/bin/x86_64-w64-mingw32-)
	$(eval EXTRA:=$(NIMOPTSWIN) -d:lto -d:mingw --cpu:amd64 --app:$(WINAPP))
	$(if $(findstring l,$(TYPEARG)), $(eval OUT=$(NAME).64.dll), $(eval OUT=$(NAME).64.exe))
	$(if $(findstring l,$(TYPEARG)), $(eval TYPEPARAM=--noMain:on --app:lib))
	$(if $(findstring s,$(TYPEARG)), $(eval TYPEPARAM=--gcc.exe:$(CPREF)gcc --gcc.linkerexe:$(CPREF)gcc --passL:-static))
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim $(COMPILERWIN) $(BASENIMOPTS) ${EXTRA} ${TYPEPARAM} -o:./target/${OUT} ${NAME}"
	if [ "$(DOCOMPRESS)" = "t" ] ; then upx --best target/${OUT} ; fi

target/${EXECNAME}.js:${BUILDDEP}
	mkdir -p target
	$(DOCKER) run --rm -v `pwd`:/usr/src/app -w /usr/src/app ${CONTAINER} bash -c "$(NIMVER) nim js $(BASENIMOPTS) ${NAME}"
	mv ${NAME}.js target/${EXECNAME}.js
	if [ "$(DOCOMPRESS)" = "t" ] ; then uglifyjs target/${EXECNAME}.js >target/${EXECNAME}.min.js ; mv target/${EXECNAME}.min.js target/${EXECNAME}.js ; fi
	echo > target/index.html "<!DOCTYPE html>"
	echo >>target/index.html '<html><head><meta charset="UTF-8"/><link href="styles.css" rel="stylesheet" type="text/css"></head><body id="body" class="site"><div id="ROOT"></div><script type="text/javascript" src="/'${EXECNAME}'.js"></script></body></html>'

install: | all install-only		## Create and install binaries to default location

install-only:	## Only install binaries, without rebuilding them
	set -e ; mkdir -p ${DEST}/all
	set -e ; rm -rf ${DEST}/all/${EXECNAME}.* ; rm -f ${DEST}/darwin-arm64/${EXECNAME} ${DEST}/darwin-x86_64/${EXECNAME} ${DEST}/darwin/${EXECNAME} ${DEST}/linux-x86_64/${EXECNAME} ${DEST}/linux-i386/${EXECNAME} ${DEST}/linux-arm/${EXECNAME} ${DEST}/linux-aarch64/${EXECNAME} ${DEST}/windows-x86_64/${EXECNAME}.exe ${DEST}/windows-i686/${EXECNAME}.exe ${DEST}/windows-x86_64/${EXECNAME}.dll ${DEST}/windows-i686/${EXECNAME}.dll
	set -e ; if [ -f target/${EXECNAME}.linux         ] ; then mkdir -p ${DEST}/linux-x86_64   && cp target/${EXECNAME}.linux         ${DEST}/all/ && ln -s ../all/${EXECNAME}.linux         ${DEST}/linux-x86_64/${EXECNAME}       ; fi
	set -e ; if [ -f target/${EXECNAME}.linux32       ] ; then mkdir -p ${DEST}/linux-i386     && cp target/${EXECNAME}.linux32       ${DEST}/all/ && ln -s ../all/${EXECNAME}.linux32       ${DEST}/linux-i386/${EXECNAME}         ; fi
	set -e ; if [ -f target/${EXECNAME}.arm.linux     ] ; then mkdir -p ${DEST}/linux-arm      && cp target/${EXECNAME}.arm.linux     ${DEST}/all/ && ln -s ../all/${EXECNAME}.arm.linux     ${DEST}/linux-arm/${EXECNAME}          ; fi
	set -e ; if [ -f target/${EXECNAME}.aarch64.linux ] ; then mkdir -p ${DEST}/linux-aarch64  && cp target/${EXECNAME}.aarch64.linux ${DEST}/all/ && ln -s ../all/${EXECNAME}.aarch64.linux ${DEST}/linux-aarch64/${EXECNAME}      ; fi
	set -e ; if [ -f target/${EXECNAME}.64.exe        ] ; then mkdir -p ${DEST}/windows-x86_64 && cp target/${EXECNAME}.64.exe        ${DEST}/all/ && ln -s ../all/${EXECNAME}.64.exe        ${DEST}/windows-x86_64/${EXECNAME}.exe ; fi
	set -e ; if [ -f target/${EXECNAME}.32.exe        ] ; then mkdir -p ${DEST}/windows-i686   && cp target/${EXECNAME}.32.exe        ${DEST}/all/ && ln -s ../all/${EXECNAME}.32.exe        ${DEST}/windows-i686/${EXECNAME}.exe   ; fi
	set -e ; if [ -f target/${EXECNAME}.64.dll        ] ; then mkdir -p ${DEST}/windows-x86_64 && cp target/${EXECNAME}.64.dll        ${DEST}/all/ && ln -s ../all/${EXECNAME}.64.exe        ${DEST}/windows-x86_64/${EXECNAME}.exe ; fi
	set -e ; if [ -f target/${EXECNAME}.32.dll        ] ; then mkdir -p ${DEST}/windows-i686   && cp target/${EXECNAME}.32.dll        ${DEST}/all/ && ln -s ../all/${EXECNAME}.32.exe        ${DEST}/windows-i686/${EXECNAME}.exe   ; fi
	set -e ; if [ -f target/${EXECNAME}.macarm        ] ; then mkdir -p ${DEST}/darwin-arm64   && cp target/${EXECNAME}.macarm        ${DEST}/all/ && ln -s ../all/${EXECNAME}.macarm        ${DEST}/darwin-arm64/${EXECNAME}       ; fi
	set -e ; if [ -f target/${EXECNAME}.macintel      ] ; then mkdir -p ${DEST}/darwin-x86_64  && cp target/${EXECNAME}.macintel      ${DEST}/all/ && ln -s ../all/${EXECNAME}.macintel      ${DEST}/darwin-x86_64/${EXECNAME}      ; fi
	set -e ; if [ -f target/${EXECNAME}.mac           ] ; then mkdir -p ${DEST}/darwin         && cp target/${EXECNAME}.mac           ${DEST}/all/ && ln -s ../all/${EXECNAME}.mac           ${DEST}/darwin/${EXECNAME}             ; fi

run:local	## Run the executable based on the config property $RUNARGS
	./target/${EXECNAME} ${RUNARGS}
