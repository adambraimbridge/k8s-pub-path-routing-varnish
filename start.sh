#!/bin/sh


shutdown() {
	log "Stopping"
	pkill varnishd
	log "Stopped varnishd $?"
	pkill varnishncsa
	log "Stopped varnishncsa $?"
       	exit 0
}

log() {
	echo "`date +'%F %T'` $1"
}

trap 'shutdown' HUP INT QUIT KILL TERM


# Start varnish and log
log "Starting"
varnishd -f /etc/varnish/default.vcl -s malloc,1024m -t 5 -p default_grace=0 &
sleep 4

varnishncsa -F '%{X-Forwarded-For}i %u %{%d/%b/%Y:%T}t %U%q %s %D "%{User-Agent}i" %{Varnish:handling}x' &
log "Started"

# Wait for the process to finish
wait ${!}
