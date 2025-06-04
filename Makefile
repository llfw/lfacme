# This source code is released into the public domain.

PREFIX?=	/usr/local
DESTDIR?=

LIBDIR?=	${DESTDIR}${PREFIX}/share/lfacme
BINDIR?=	${DESTDIR}${PREFIX}/sbin
CONFDIR?=	${DESTDIR}${PREFIX}/etc
MANDIR?=	${DESTDIR}${PREFIX}/share/man
MAN5DIR?=	${MANDIR}/man5
MAN7DIR?=	${MANDIR}/man7
MAN8DIR?=	${MANDIR}/man8
HOOKDIR?=	${CONFDIR}/hooks

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

PERIODICDIR=	/usr/local/etc/periodic/daily
PERIODICMODE?=	0755
PERIODIC=	900.lfacme.sh

default: all

all:
	@echo "Nothing to do."

install: install-lib install-bin install-conf install-hook install-man install-periodic

install-lib:
	@echo 'create ${LIBDIR}'; install -d ${LIBDIR}
	@for lib in ${LIB}; do \
		echo "install ${LIBDIR}/$$lib"; \
		install -C -m ${LIBMODE} "$$lib" "${LIBDIR}/$$lib"; \
	done
	@echo 'create ${LIBDIR}/challenge'; install -d ${LIBDIR}/challenge;
	@for challenge in ${CHALLENGE}; do \
		basename=$${challenge%*.sh}; \
		echo "install ${LIBDIR}/challenge/$$basename"; \
		install -C -m ${CHALLENGEMODE} "$$challenge" \
			"${LIBDIR}/challenge/$$basename"; \
	done

install-bin:
	@echo 'create ${BINDIR}'; install -d ${BINDIR}
	@for bin in ${BIN}; do \
		basename=$${bin%*.sh}; \
		echo "install ${BINDIR}/$$basename"; \
		install -C -m ${BINMODE} "$$bin" "${BINDIR}/$$basename"; \
	done

install-conf:
	@echo 'create ${CONFDIR}'; install -d ${CONFDIR};
	@for conf in ${CONF}; do \
		echo "install ${CONFDIR}/$$conf"; \
		install -C -m ${CONFMODE} "$$conf" "${CONFDIR}/$$conf"; \
	done

install-hook:
	@echo 'create ${HOOKDIR}'; install -d ${HOOKDIR};
	@for hook in ${HOOK}; do \
		basename=$${hook%*.sh}; \
		echo "install ${HOOKDIR}/$$basename"; \
		install -C -m ${HOOKMODE} "$$hook" "${HOOKDIR}/$$basename"; \
	done

install-man:
	@echo 'create ${MANDIR}'; install -d ${MANDIR}
	@echo 'create ${MAN5DIR}'; install -d ${MAN5DIR}
	@for man in ${MAN5}; do \
		echo "install ${MAN5DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${MAN5DIR}/$$man"; \
	done
	@echo 'create ${MAN7DIR}'; install -d ${MAN7DIR}
	@for man in ${MAN7}; do \
		echo "install ${MAN7DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${MAN7DIR}/$$man"; \
	done
	@echo 'create ${MAN8DIR}'; install -d ${MAN8DIR}
	@for man in ${MAN8}; do \
		echo "install ${MAN8DIR}/$$man"; \
		install -C -m ${MANMODE} "$$man" "${MAN8DIR}/$$man"; \
	done

install-periodic:
	@if [ $$(uname) = "FreeBSD" ]; then \
		echo 'create ${PERIODICDIR}'; install -d ${PERIODICDIR}; \
		for periodic in ${PERIODIC}; do \
			basename=$${periodic%*.sh}; \
			echo "install ${PERIODICDIR}/$$basename"; \
			install -C -m ${PERIODICMODE} "$$periodic" \
				"${PERIODICDIR}/$$basename"; \
		done; \
	fi

.PHONY:	default all install install-lib install-bin install-conf \
	install-hook install-man install-periodic
