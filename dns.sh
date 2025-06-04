#! /bin/sh
# This source code is released into the public domain.

. /usr/local/share/lfacme/init.sh
. /usr/local/share/lfacme/dnsutils.sh

# begin, done or failed
ACTION=$1
# ACME method, must be dns-01.
METHOD=$2
# This is the full domain name we're authorising.
DOMAIN=$3
# Token name, not used for dns-01.
TOKEN=$4
# The token value we need to create.
AUTH=$5

if [ "$#" -ne 5 ]; then
	_fatal "missing arguments"
fi

if [ "$METHOD" != "dns-01" ]; then
	exit 1
fi

if [ -z "$ACME_DNS_KEYFILE" ]; then
	_fatal "ACME_DNS_KEYFILE not configured"
fi

# Add a new record using nsupdate.
_add_record() {
	local domain="$1"
	local auth="$2"

	nsupdate -k "$ACME_DNS_KEYFILE" <<EOF
update add _acme-challenge.${DOMAIN}. 300 IN TXT "${AUTH}"
send
EOF
	return $?
}

# Remove an existing record using nsupdate.
_remove_record() {
	local domain="$1"
	local auth="$2"

	nsupdate -k "$ACME_DNS_KEYFILE" <<EOF
update delete _acme-challenge.${DOMAIN}. 300 IN TXT "${AUTH}"
send
EOF
	return $?
}

case "$ACTION" in
	begin)
		if ! _add_record "$DOMAIN" "$AUTH"; then
			_fatal "failed to add the DNS record for %s" "$DOMAIN"
			exit 1
		fi

		if ! lfacme_dns_wait_for_record "$DOMAIN" "$AUTH"; then
			_fatal "timed out waiting for the DNS record for '%s' to be published" \
				"$DOMAIN"
			exit 1
		fi

		exit 0
		;;

	done|failed)
		_remove_record "$DOMAIN" "$AUTH"
		exit $?
		;;

	*)
		_fatal "unknown action: %s" "$ACTION"
		;;
esac
