PREFIX?=	/usr/local
LIBDIR?=	${DESTDIR}/${PREFIX}/share/lfacme
BINDIR?=	${DESTDIR}/${PREFIX}/sbin
CONFDIR?=	${DESTDIR}/${PREFIX}/etc
MANDIR?=	${DESTDIR}/${PREFIX}/share/man
MAN5DIR?=	${MANDIR}/man5
MAN8DIR?=	${MANDIR}/man8
HOOKDIR?=	${CONFDIR}/hooks

LIBMODE?=	0644
LIB_FILES=	init.sh \
		kerberos-challenge.sh

BINMODE?=	0755
BIN_FILES=	lfacme-renew.sh \
		lfacme-setup.sh

CONFMODE?=	0644
CONF_FILES=	acme.conf.sample \
		domains.conf.sample

HOOKMODE?=	0755
HOOK_FILES=	example-hook.sh

MANMODE?=	0644
MAN5FILES=	acme.conf.5 \
		domains.conf.5
MAN8FILES=	lfacme-renew.8 \
		lfacme-setup.8

default: all

all: 
	@echo "Nothing to do."

install:
	@echo 'create ${LIBDIR}'; install -d ${LIBDIR}; \
	for lib in ${LIB_FILES}; do \
		echo "install ${LIBDIR}/$$lib"; \
		install -C -m ${LIBMODE} "$$lib" "${LIBDIR}/$$lib"; \
	done; \
	\
	echo 'create ${BINDIR}'; install -d ${BINDIR}; \
	for bin in ${BIN_FILES}; do \
		basename=$${bin%*.sh}; \
		echo "install ${BINDIR}/$$basename"; \
		install -C -m ${BINMODE} "$$bin" "${BINDIR}/$$basename"; \
	done; \
	\
	echo 'create ${CONFDIR}'; install -d ${CONFDIR}; \
	for conf in ${CONF_FILES}; do \
		echo "install ${CONFDIR}/$$conf"; \
		install -C -m ${CONFMODE} "$$conf" "${CONFDIR}/$$conf"; \
	done; \
	\
	echo 'create ${HOOKDIR}'; install -d ${HOOKDIR}; \
	for hook in ${HOOK_FILES}; do \
		basename=$${hook%*.sh}; \
		echo "install ${HOOKDIR}/$$basename"; \
		install -C -m ${HOOKMODE} "$$hook" "${HOOKDIR}/$$basename"; \
	done; \
	\
	echo 'create ${MANDIR}'; install -d ${MANDIR}; \
	\
	echo 'create ${MAN5DIR}'; install -d ${MAN5DIR}; \
	for man in ${MAN5FILES}; do \
		echo "install ${MAN5DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${MAN5DIR}/$$man"; \
	done; \
	\
	echo 'create ${MAN8DIR}'; install -d ${MAN8DIR}; \
	for man in ${MAN8FILES}; do \
		echo "install ${MAN8DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${MAN8DIR}/$$man"; \
	done; \
