#! /bin/sh
# This source code is released into the public domain.
#
# An example hook.

# Action is always 'newcert', at least for now.
action="$1"

# Environment variables:
# $LFACME_CERT is the name of the certificate
# $LFACME_CERTFILE is the filename of the certificate.
# $LFACME_KEYFILE is the filename of the private key.

set -e

case "$action" in
newcert)
	# The certificate was issued or renewed.
	cp "$LFACME_CERTFILE" /usr/local/etc/nginx/tls/cert.pem
	cp "$LFACME_KEYFILE" /usr/local/etc/nginx/tls/key.pem
	nginx -s reload
	;;

*)
	# Ignore unknown actions, because new ones might be added later.
	;;
esac
