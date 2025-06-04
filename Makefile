# This source code is released into the public domain.

# These directories may be customised to change where things are installed.
# To avoid issues when updating, consider providing the new values on the
# make(1) command line instead of editing this file.

PREFIX?=	/usr/local
DESTDIR?=

LIBDIR?=	${PREFIX}/share/lfacme
BINDIR?=	${PREFIX}/sbin
CONFDIR?=	${PREFIX}/etc/lfacme
MANDIR?=	${PREFIX}/share/man
PERIODICDIR=	${PREFIX}/etc/periodic/daily
MAN5DIR?=	${MANDIR}/man5
MAN7DIR?=	${MANDIR}/man7
MAN8DIR?=	${MANDIR}/man8
HOOKDIR?=	${CONFDIR}/hooks

### No user-servicable parts below this point.

LIBMODE?=	0644
LIB=		init.sh dnsutils.sh

CHALLENGEMODE?=	0755
CHALLENGE=	dns.sh \
		http.sh \
		kerberos.sh

BINMODE?=	0755
BIN=		lfacme-renew.sh \
		lfacme-setup.sh

CONFMODE?=	0644
CONF=		acme.conf.sample \
		domains.conf.sample

HOOKMODE?=	0755
HOOK=		example-hook.sh

MANMODE?=	0644
MAN5=		acme.conf.5 \
		domains.conf.5
MAN7=		lfacme.7 \
		lfacme-dns.7 \
		lfacme-http.7 \
		lfacme-kerberos.7
MAN8=		lfacme-renew.8 \
		lfacme-setup.8

PERIODICMODE?=	0755
PERIODIC=	900.lfacme.sh

SED?=		sed
REPLACE=	sed	-e 's,__PREFIX__,${PREFIX},g' \
			-e 's,__CONFDIR__,${CONFDIR},g' \
			-e 's,__LIBDIR__,${LIBDIR},g' \
			-e 's,__BINDIR__,${BINDIR},g'

.PHONY:	default all install install-lib install-bin install-conf \
	install-hook install-man install-periodic
.SUFFIXES: .5 .5.in .7 .7.in .8 .8.in .sh .sh.in .sample .sample.in

default: all

all: ${MAN5} ${MAN7} ${MAN8} ${LIB} ${BIN} ${CHALLENGE} ${HOOK} ${PERIODIC} ${CONF}

clean:
	rm -f ${MAN5} ${MAN7} ${MAN8} ${LIB} ${BIN}
	rm -f ${HOOK} ${CHALLENGE} ${PERIODIC} ${CONF}

.sh.in.sh:
	${REPLACE} <$< >$@

.sample.in.sample:
	${REPLACE} <$< >$@

.5.in.5:
	${REPLACE} <$< >$@

.7.in.7:
	${REPLACE} <$< >$@

.8.in.8:
	${REPLACE} <$< >$@

install: install-lib install-bin install-conf install-hook install-man install-periodic

install-lib: all
	@echo 'create ${DESTDIR}${LIBDIR}'; install -d ${DESTDIR}${LIBDIR}
	@for lib in ${LIB}; do \
		echo "install ${DESTDIR}${LIBDIR}/$$lib"; \
		install -C -m ${LIBMODE} "$$lib" "${DESTDIR}${LIBDIR}/$$lib"; \
	done
	@echo 'create ${DESTDIR}${LIBDIR}/challenge'; install -d ${DESTDIR}${LIBDIR}/challenge;
	@for challenge in ${CHALLENGE}; do \
		basename=$${challenge%*.sh}; \
		echo "install ${DESTDIR}${LIBDIR}/challenge/$$basename"; \
		install -C -m ${CHALLENGEMODE} "$$challenge" \
			"${DESTDIR}${LIBDIR}/challenge/$$basename"; \
	done

install-bin: all
	@echo 'create ${DESTDIR}${BINDIR}'; install -d ${DESTDIR}${BINDIR}
	@for bin in ${BIN}; do \
		basename=$${bin%*.sh}; \
		echo "install ${DESTDIR}${BINDIR}/$$basename"; \
		install -C -m ${BINMODE} "$$bin" "${DESTDIR}${BINDIR}/$$basename"; \
	done

install-conf: all
	@echo 'create ${DESTDIR}${CONFDIR}'; install -d ${DESTDIR}${CONFDIR};
	@for conf in ${CONF}; do \
		echo "install ${DESTDIR}${CONFDIR}/$$conf"; \
		install -C -m ${CONFMODE} "$$conf" "${DESTDIR}${CONFDIR}/$$conf"; \
	done

install-hook: all
	@echo 'create ${DESTDIR}${HOOKDIR}'; install -d ${DESTDIR}${HOOKDIR};
	@for hook in ${HOOK}; do \
		basename=$${hook%*.sh}; \
		echo "install ${DESTDIR}${HOOKDIR}/$$basename"; \
		install -C -m ${HOOKMODE} "$$hook" "${DESTDIR}${HOOKDIR}/$$basename"; \
	done

install-man: all
	@echo 'create ${DESTDIR}${MANDIR}'; install -d ${DESTDIR}${MANDIR}
	@echo 'create ${DESTDIR}${MAN5DIR}'; install -d ${DESTDIR}${MAN5DIR}
	@for man in ${MAN5}; do \
		echo "install ${DESTDIR}${MAN5DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${DESTDIR}${MAN5DIR}/$$man"; \
	done
	@echo 'create ${DESTDIR}${MAN7DIR}'; install -d ${DESTDIR}${MAN7DIR}
	@for man in ${MAN7}; do \
		echo "install ${DESTDIR}${MAN7DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${DESTDIR}${MAN7DIR}/$$man"; \
	done
	@echo 'create ${DESTDIR}${MAN8DIR}'; install -d ${DESTDIR}${MAN8DIR}
	@for man in ${MAN8}; do \
		echo "install ${DESTDIR}${MAN8DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${DESTDIR}${MAN8DIR}/$$man"; \
	done

install-periodic: all
	@if [ $$(uname) = "FreeBSD" ]; then \
		echo 'create ${DESTDIR}${PERIODICDIR}'; install -d ${DESTDIR}${PERIODICDIR}; \
		for periodic in ${PERIODIC}; do \
			basename=$${periodic%*.sh}; \
			echo "install ${DESTDIR}${PERIODICDIR}/$$basename"; \
			install -C -m ${PERIODICMODE} "$$periodic" \
				"${DESTDIR}${PERIODICDIR}/$$basename"; \
		done; \
	fi
