#! /bin/sh
# This source code is released into the public domain.

. /usr/local/share/lfacme/init.sh

# begin, done or failed
ACTION=$1
# ACME method, must be http-01.
METHOD=$2
# The full domain name we're authorising.
DOMAIN=$3
# Token name.
TOKEN=$4
# The token value we need to create.
AUTH=$5

if [ "$#" -ne 5 ]; then
	_fatal "missing arguments"
fi

if [ "$METHOD" != "http-01" ]; then
	_warn "skip method %s" "$METHOD"
	exit 1
fi

if [ -z "$ACME_HTTP_CHALLENGE_DIR" ]; then
	_fatal "must set ACME_HTTP_CHALLENGE_DIR"
fi

if ! [ -d "$ACME_HTTP_CHALLENGE_DIR" ]; then
	_fatal "missing $ACME_HTTP_CHALLENGE_DIR"
fi

_file="${ACME_HTTP_CHALLENGE_DIR}/${TOKEN}"

case "$ACTION" in
	begin)
		echo "$AUTH" >"$_file"
		exit $?
		;;

	done|failed)
		rm -f "$_file"
		exit $?
		;;

	*)
		_fatal "unknown action: %s" "$ACTION"
		;;
esac
