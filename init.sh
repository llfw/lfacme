# This source code is released into the public domain.

_BASEDIR="/usr/local"
_SHARE="${_BASEDIR}/share/lfacme"
_CONFDIR="${_BASEDIR}/etc/lfacme"
_CONFIG="${_CONFDIR}/acme.conf"
_DOMAINS="${_CONFDIR}/domains.conf"
_UACME=/usr/local/bin/uacme
_UACME_DIR="${_CONFDIR}/certs"

_PROGNAME="$0"

_uacme() {
	"$_UACME" -a "$ACME_URL" -c "$_UACME_DIR" "$@"
}

_fatal() {
	local _fmt=$1; shift
	local _msg="$(printf "$_fmt" "$@")"
	printf >&2 '%s: FATAL: %s\n' "$_PROGNAME" "$_msg"
	exit 1
}

_error() {
	local _fmt=$1; shift
	local _msg="$(printf "$_fmt" "$@")"
	printf >&2 '%s: ERROR: %s\n' "$_PROGNAME" "$_msg"
}

_warn() {
	local _fmt=$1; shift
	local _msg="$(printf "$_fmt" "$@")"
	printf >&2 '%s: WARNING: %s\n' "$_PROGNAME" "$_msg"
}

if ! [ -f "$_CONFIG" ]; then
	_fatal "missing %s" "$_CONFIG"
fi

. "$_CONFIG"

if [ -z "$ACME_URL" ]; then
	_fatal "ACME_URL must be set in %s" "$_CONFIG"
fi

if [ -z "$ACME_DIR" ]; then
	_fatal "ACME_DIR must be set in %s" "$_CONFIG"
fi

if [ -z "$ACME_KERBEROS_PRINCIPAL" ]; then
	ACME_KERBEROS_PRINCIPAL="host/$(hostname)"
fi

if [ -z "$ACME_HOOKDIR" ]; then
	ACME_HOOKDIR="${_CONFDIR}/hooks"
fi
