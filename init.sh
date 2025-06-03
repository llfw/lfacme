# This source code is released into the public domain.

_PROGNAME="$0"

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

# The prefix we're installed in.
_BASEDIR="/usr/local"
# Where the internal scripts are.
_SHARE="${_BASEDIR}/share/lfacme"

# Our configuration directory.  This might be overridden by command-line
# arguments.
if [ -z "$_CONFDIR" ]; then
	_CONFDIR="${_BASEDIR}/etc/lfacme"
fi

# Our configuration file.
_CONFIG="${_CONFDIR}/acme.conf"

# Read and validate the configuration file.

if ! [ -f "$_CONFIG" ]; then
	_fatal "missing %s" "$_CONFIG"
fi

. "$_CONFIG"

if [ -z "$ACME_URL" ]; then
	_fatal "ACME_URL must be set in %s" "$_CONFIG"
fi

if [ -z "$ACME_DATADIR" ]; then
	ACME_DATADIR="/var/db/lfacme"
fi

if [ -z "$ACME_KERBEROS_PRINCIPAL" ]; then
	ACME_KERBEROS_PRINCIPAL="host/$(hostname)"
fi

if [ -z "$ACME_HOOKDIR" ]; then
	ACME_HOOKDIR="${ACME_CONFDIR}/hooks"
fi

# The domains.conf file.
_DOMAINS="${_CONFDIR}/domains.conf"

# uacme's base directory; this is where it puts certificates.
_UACME_DIR="${ACME_DATADIR}/certs"

# The uacme executable.
_UACME=/usr/local/bin/uacme

_uacme() {
	"$_UACME" -a "$ACME_URL" -c "$_UACME_DIR" "$@"
}
