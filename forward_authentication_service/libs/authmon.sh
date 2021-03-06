#!/bin/sh
#Copyright (C) BlueWave Projects and Services 2015-2021
#This software is released under the GNU GPL license.

#wait a while for openNDS to get started
sleep 5

#get arguments and set variables
url=$1
gatewayhash=$2
phpcli=$3
loopinterval=10
postrequest="/usr/lib/opennds/post-request.php"

#action can be "list" (list and delete from FAS auth log) or "view" (view and leave in FAS auth log)
#
# For debugging purposes, action can be set to "view"
#action="view"
# For normal running, action will be set to "list"
action="list"

do_ndsctl () {
	local timeout=4

	for tic in $(seq $timeout); do
		ndsstatus="ready"
		ndsctlout=$(ndsctl $ndsctlcmd)

		for keyword in $ndsctlout; do

			if [ $keyword = "locked" ]; then
				ndsstatus="busy"
				sleep 1
				break
			fi
		done

		if [ "$ndsstatus" = "ready" ]; then
			break
		fi
	done
}

ndsctlcmd="status 2>/dev/null"
do_ndsctl

version=$(echo "$ndsctlout" | grep Version | awk '{printf $2}')
user_agent="openNDS(authmon;NDS:$version;)"

while true; do
	authlist=$($phpcli -f "$postrequest" "$url" "$action" "$gatewayhash" "$user_agent")
	validator=${authlist:0:1}

	if [ "$validator" = "*" ]; then
		authlist=${authlist:1:1024}

		if [ ${#authlist} -ge 2 ]; then

			for authparams in $authlist; do
				authparams=$(printf "${authparams//%/\\x}")
				logger -s -p daemon.notice -t "authmon" "authentication parameters $authparams"
				echo $authparams
				ndsctlcmd="auth $authparams 2>/dev/null"
				do_ndsctl

				if [ "$ndsstatus" = "busy" ]; then
				 logger -s -p daemon.err -t "authmon" "ERROR: ndsctl is in use by another process"
				fi
			done
		fi
	else
		for keyword in $authlist; do

			if [ $keyword = "ERROR:" ]; then
				logger -s -p daemon.err -t "authmon" "[$authlist]"
				break
			fi
		done
	fi

	sleep $loopinterval
done

