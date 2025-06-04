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

_verbose() {
	if [ -z "$LFACME_VERBOSE" ]; then
		return
	fi

	local _fmt=$1; shift
	local _msg="$(printf "$_fmt" "$@")"
	printf '%s: %s\n' "$_PROGNAME" "$_msg"
}

# The prefix we're installed in.
_BASEDIR="/usr/local"
# Where the internal scripts are.
_SHARE="${_BASEDIR}/share/lfacme"
_CHALLENGE="${_SHARE}/challenge"

# Our configuration directory.  If $_CONFDIR is already set, then the script
# wants to provide its own config directory, probably from a command line
# argument.  Otherwise if $LFACME_CONFDIR is set, we're running in a hook
# script, so use that as the config directory.  Otherwise, use the default.
if [ -z "$_CONFDIR" ]; then
	if ! [ -z "$LFACME_CONFDIR" ]; then
		_CONFDIR="$LFACME_CONFDIR"
	else
		_CONFDIR="${_BASEDIR}/etc/lfacme"
	fi
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
	ACME_HOOKDIR="${_CONFDIR}/hooks"
fi

# The domains.conf file.
_DOMAINS="${_CONFDIR}/domains.conf"

# uacme's base directory; this is where it puts certificates.
_UACME_DIR="${ACME_DATADIR}/certs"

# The uacme executable.
_UACME=/usr/local/bin/uacme

_LFACME_UACME_FLAGS=""
if ! [ -z "$LFACME_VERBOSE" ]; then
	_LFACME_UACME_FLAGS="$_LFACME_UACME_FLAGS -v"
fi

_uacme() {
	env	"LFACME_CONFDIR=${_CONFDIR}"		\
		"LFACME_VERBOSE=${LFACME_VERBOSE}"	\
		"$_UACME" $_LFACME_UACME_FLAGS 		\
		-a "$ACME_URL" -c "$_UACME_DIR" "$@"
}

# Find a challenge script and make sure it's valid.  If the challenge name
# begins with a '/' it's a full path, otherwise we search $_CHALLENGE and
# $_CONFDIR/challenge.
_findchallenge() {
	local identifier="$1"
	local challenge="$2"
	local path=""

	if [ "${challenge#/*}" != "$challenge" ]; then
		path="${challenge}"
	elif [ -f "${_CHALLENGE}/${challenge}" ]; then
		path="${_CHALLENGE}/${challenge}"
	elif [ -f "${_CONFDIR}/challenge/${challenge}" ]; then
		path="${_CONFDIR}/challenge/${challenge}"
	else
		_error "%s: could not find challenge script '%s'" \
			"$identifier" "$challenge"
		return 1
	fi

	if ! [ -x "$path" ]; then
		_error "%s: challenge is not executable: %s" \
			"$identifier" "$path"
		return 1
	fi

	echo "$path"
}

# Find a hook script and make sure it's valid.  If the hook name begins with a
# '/' it's a full path, otherwise it's relative to ACME_HOOKDIR.
_findhook() {
	local identifier="$1"
	local hook="$2"

	if [ "${hook#/*}" = "$hook" ]; then
		hook="${ACME_HOOKDIR}/$hook"
	fi

	if ! [ -f "$hook" ]; then
		_error "%s: hook does not exist: %s" \
			"$identifier" "$hook"
		return 1
	fi

	if ! [ -x "$hook" ]; then
		_error "%s: hook is not executable: %s" \
			"$identifier" "$hook"
		return 1
	fi

	echo "$hook"
}
