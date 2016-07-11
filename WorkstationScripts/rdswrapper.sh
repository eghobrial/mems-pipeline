#!/bin/sh
# Script: /root/rdswrapper.sh 

case "$SSH_ORIGINAL_COMMAND" in
	"ps")
		ps -ef
		;;
	"killrds")
		/usr/bin/killall -9 rdsClient
		;;
	"checkrds")
		/bin/ps -ef |grep rdsClient
		;;
	*)
		echo "Sorry. Only these commands are available to you:"
		echo "ps, killrds"
		exit 1
		;;
esac