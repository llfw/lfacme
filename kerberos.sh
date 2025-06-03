#! /bin/sh
# This source code is released into the public domain.

. /usr/local/share/lfacme/init.sh

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

if [ -z "$ACME_KERBEROS_KEYTAB" ]; then
	ACME_KERBEROS_KEYTAB="/etc/krb5.keytab"
fi

if ! kinit -k -t "$ACME_KERBEROS_KEYTAB" "$ACME_KERBEROS_PRINCIPAL"; then
	_fatal "failed to obtain a Kerberos ticket"
fi

# Keep removing labels from the name until we find one with nameservers.
_getnameservers() {
	local domain="$1"

	local _trydomain="$domain"
	while ! [ -z "$_trydomain" ]; do
		if [ "$_trydomain" = "${_trydomain#*.}" ]; then
			# If there are no dots in the domain, we couldn't
			# find the nameservers.
			break
		fi

		# For CNAME records, a query for NS will return the CNAME.
		# Therefore we have to check we actually got NS records.
		local nameservers="$(
			dig "$_trydomain" ns +noall +answer | \
			awk '$4 == "NS" { print $5 }'
		)"

		if ! [ -z "$nameservers" ]; then
			echo "$nameservers"
			return
		fi

		_trydomain="${_trydomain#*.}"
	done

	_fatal "unable to find nameservers for %s" "$_trydomain"
}

# Add a new record using nsupdate.
_add_record() {
	local domain="$1"
	local auth="$2"

	nsupdate -g <<EOF
update add _acme-challenge.${DOMAIN}. 300 IN TXT "${AUTH}"
send
EOF
	return $?
}

# Remove an existing record using nsupdate.
_remove_record() {
	local domain="$1"
	local auth="$2"

	nsupdate -g <<EOF
update delete _acme-challenge.${DOMAIN}. 300 IN TXT "${AUTH}"
send
EOF
	return $?
}

# Wait for the DNS record to appear on a specific nameserver.
_wait_for_nameserver() {
	local domain="$1"
	local auth="$2"
	local nameserver="$3"

	echo "waiting for $domain on nameserver $ns..."

	local waited=0
	local waitlimit=60
	while sleep 1; do
		waited=$((waited + 1))
		if [ "$waited" -ge "$waitlimit" ]; then
			_error "timed out waiting for nameserver update for %s" \
				"$domain"
			return 1
		fi

		local _rdatas="$(
			dig "_acme-challenge.$domain" txt @$nameserver \
				+noall +answer \
			| awk '$4 == "TXT" { print $5 }'
		)"
		for rdata in $_rdatas; do
			if [ "$rdata" = "\"$auth\"" ]; then
				return 0
			fi
		done
	done
}

# Wait for DNS servers to have the given record.
_wait_for_record() {
	local domain="$1"
	local auth="$2"
	local nameservers="$(_getnameservers "$domain")"

	for ns in $nameservers; do
		_wait_for_nameserver "$domain" "$auth" "$ns" || return 1
	done

	return 0
}

case "$ACTION" in
	begin)
		_add_record "$DOMAIN" "$AUTH" \
		&& _wait_for_record "$DOMAIN" "$AUTH"
		exit $?
		;;

	done|failed)
		_remove_record "$DOMAIN" "$AUTH"
		exit $?
		;;

	*)
		_fatal "unknown action: %s" "$ACTION"
		;;
esac
