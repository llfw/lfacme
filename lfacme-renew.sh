#! /bin/sh
# This source code is released into the public domain.

# Parse command-line arguments.
args=$(getopt c:v $*)
if [ $? -ne 0 ]; then
	exit 1
fi
set -- $args

# ARI is broken due to https://github.com/ndilieto/uacme/issues/91
_uacme_flags="--no-ari"

while :; do
	case "$1" in
	-c)
		_CONFDIR="$2"
		shift; shift;;
	-v)
		LFACME_VERBOSE=1
		shift;;
	--)
		shift; break;;
	esac
done

# Initialise.
. /usr/local/share/lfacme/init.sh

if ! [ -f "$_UACME_DIR/private/key.pem" ]; then
	_fatal "run lfacme-setup first"
fi

if ! [ -f "$_DOMAINS" ]; then
	_fatal "missing $_DOMAINS"
fi

# Create a key if it doesn't already exist.  It would be better to always
# create a new key here, but currently uacme doesn't have a way to tell us
# that we need to do that.
_make_key() {
	local keytype="$1"
	local keyfile="$2"

	if [ -s "$keyfile" ]; then
		return 0
	fi

	local _umask=$(umask)
	umask 077

	case $keytype in
	ec)	openssl ecparam -name secp384r1 -genkey -noout -out "$keyfile";;
	rsa)	openssl genrsa -out "$keyfile" 3072;;
	*)	_error "%s: unknown key type %s?" "$keyfile" "$keytype"
		return 1;;
	esac

	local _ret=$?
	umask $_umask

	return $_ret
}

# Create a new CSR for a domain.
_make_csr() {
	local csrfile="$1"
	local keyfile="$2"
	local domain="$3"
	local altnames="$4"
	local csrconf="${csrfile}.cnf"

	cat >"$csrconf" <<EOF
[req] 
distinguished_name = req_distinguished_name
req_extensions = req_ext
prompt = no

[req_distinguished_name] 
commonName = $domain

[req_ext] 
subjectAltName = @alt_names 

[alt_names] 
DNS.1 = $domain
EOF
	
	local _i=2
	for altname in $altnames; do
		printf >>"$csrconf" 'DNS.%d = %s\n' "$_i" "$altname"
		_i=$((_i + 1))
	done

	# Generate the CSR
	openssl req -new -key "$keyfile" -out "$csrfile" -config "$csrconf"
	return $?
}

# Process a single cert.
_docert() {
	local identifier="$1"; shift

	_verbose "checking certificate '%s'" "$identifier"

	# uacme creates the cert name by stripping the extension from the
	# CSR filename, so the basename has to match the identifier.
	local dir="${_UACME_DIR}/${identifier}"
	local keyfile="${dir}/${identifier}-key.pem"
	local csrfile="${dir}/${identifier}.csr"
	local certfile="${dir}/${identifier}-cert.pem"

	# these can be overridden by args
	local keytype=""
	local altnames=""
	local hooks=""
	local domain=""
	local challenge=""

	# parse arguments for this cert
	while ! [ -z "$1" ]; do
		case "$1" in
		type=rsa)
			keytype=rsa
			;;
		type=ec)
			keytype=ec
			;;
		type=*)
			_error "%s: unknown key type: %s" \
				"$identifier" "${1#type=*}"
			return 1
			;;
		hook=*)
			hooks="$hooks ${1#hook=*}"
			;;
		challenge=*)
			challenge="${1#challenge=*}"
			;;
		*=*)
			_error "%s: unknown option: %s" "$identifier" "$1"
			return 1
			;;
		*.*)
			altnames="$altnames $1"
			# Take the domain from the first altname.
			if [ -z "$domain" ]; then
				domain="$1"
			fi
			;;
		*)
			_error "%s: unknown option: %s" "$identifier" "$1"
			return 1
			;;
		esac
		shift
	done

	# If no altnames were given, the identifier is the domain.
	if [ -z "$domain" ]; then
		domain="$identifier"
	fi

	# Default key type is ec.
	if [ -z "$keytype" ]; then
		keytype="ec"
	fi

	# Default challenge is http.
	if [ -z "$challenge" ]; then
		challenge="http"
	fi

	# make sure the challenge is valid.
	challenge_path="$(_findchallenge "$identifier" "$challenge")"
	if [ "$?" -ne 0 ]; then
		return 1
	fi

	# make sure all the hook scripts are valid.  if the hook name
	# begins with a '/' it's a full path, otherwise it's relative
	# to ACME_HOOKDIR.
	local _rhooks=""
	for hook in $hooks; do
		local _hookpath="$(_findhook "$identifier" "$hook")"
		if [ "$?" -ne 0 ]; then
			return 1
		fi

		_rhooks="$_rhooks $_hookpath"
	done

	mkdir -p -m0700 "$dir"

	if ! _make_key "$keytype" "$keyfile"; then
		_error "%s: could not create a new private key" "$identifier"
		return 1
	fi

	if ! _make_csr "$csrfile" "$keyfile" "$domain" "$altnames"; then
		_error "%s: could not create the certificate signing request" \
			"$identifier"
		return 1
	fi

	_uacme $_uacme_flags 		\
		-h "$challenge_path"	\
		 issue "$csrfile"
	_ret=$?

	# exit 1 means the cert wasn't reissued
	if [ "$_ret" -eq 1 ]; then
		return 0
	fi

	# exit 2 means an actual error
	if [ "$_ret" -eq 2 ]; then
		_error "%s: failed to issue certificate" "$identifier"
		return 1
	fi

	# any other non-zero exit code is unexpected
	if [ "$_ret" -ne 0 ]; then
		_error "%s: unexpected exit code from uacme: %d" \
			"$identifier" "$_ret"
		return 1
	fi

	# otherwise, exit code is 0 which means we (re)issued the cert,
	# so run the hooks.
	for hook in $_rhooks; do
		_verbose "running hook: %s" "$hook"
		env	"LFACME_CONFDIR=${_CONFDIR}"		\
			"LFACME_VERBOSE=${LFACME_VERBOSE}"	\
			"LFACME_CERT=${identifier}"		\
			"LFACME_KEYFILE=${keyfile}"		\
			"LFACME_CERTFILE=${certfile}"		\
			"$hook" newcert
		if [ "$?" -ne 0 ]; then
			_warn "%s: hook script '%s' failed" \
				"$identifier" "$hook"
		fi
		# should we do anything if the hook failed?
	done

	return $?
}

_exit=0
_default_args=""

cat "$_DOMAINS" \
| egrep -v '^(#|[[:space:]]*$)' \
| while read identifier args; do

	if [ "$identifier" = "*" ]; then
		_default_args="$args"
		continue
	fi

	if ! _docert "$identifier" $_default_args $args; then
		_exit=1
	fi
done

exit $_exit
