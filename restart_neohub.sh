#!/bin/bash

HUB_IP=
HUB_PORT=4243
HUB_TOKEN=
PUSHOVER_API_TOKEN=
PUSHOVER_USER_KEY=
REBOOT_VERIFICATION_DELAY_IN_MINUTES=5
REBOOT_VERIFICATION_DELAY_IN_SECONDS=$(($REBOOT_VERIFICATION_DELAY_IN_MINUTES*60))
REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_MINUTES=15
REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_SECONDS=$(($REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_MINUTES*60))

date=$(TZ='Europe/Amsterdam' date '+%d-%m-%Y %H:%M:%S')

push_to_mobile(){
	local t="${1:-cli-app}"
	local m="$2"
	[[ "$m" != "" ]] && curl -s \
		--form-string "token=${PUSHOVER_API_TOKEN}" \
		--form-string "user=${PUSHOVER_USER_KEY}" \
		--form-string "title=$t" \
		--form-string "message=$m" \
		https://api.pushover.net/1/messages.json
	echo ""
	echo "$date - Sent push notification"
}

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "$date - Running restart_neohub.sh"

WSCAT_OUTPUT=`script -q -e -c 'wscat -n -w 2 -x '"'"'{"message_type":"hm_get_command_queue","message":"{\"token\":\"'"'$HUB_TOKEN'"'\",\"COMMANDS\":[{\"COMMAND\":\"{'"'"'"'"'"'"'"'"'GET_SYSTEM'"'"'"'"'"'"'"'"':0}\",\"COMMANDID\":1}]}"}'"' -c \"wss://$HUB_IP:$HUB_PORT\""`
echo $WSCAT_OUTPUT | grep HUB_VERSION > /dev/null
HUB_VERSION_EXIT_STATUS_CODE=$?

if [[ $HUB_VERSION_EXIT_STATUS_CODE -gt 0 ]]
then
	echo "$date - Failed to set up a connection to NeoHub - please restart it manually"
	push_to_mobile "NeoHub cron" "The restart cronjob failed to connect - please restart it manually"
	exit 1
fi

EAT_OUTPUT=`script -q -e -c 'wscat -n -w 2 -x '"'"'{"message_type":"hm_get_command_queue","message":"{\"token\":\"'"'$HUB_TOKEN'"'\",\"COMMANDS\":[{\"COMMAND\":\"{'"'"'"'"'"'"'"'"'RESET'"'"'"'"'"'"'"'"':0}\",\"COMMANDID\":1}]}"}'"' -c \"wss://$HUB_IP:$HUB_PORT\""`
echo "$date - Successfully sent restart command to the NeoHub"

echo "$date - Sleeping for $REBOOT_VERIFICATION_DELAY_IN_MINUTES minutes before checking for successful reboot"
sleep $REBOOT_VERIFICATION_DELAY_IN_SECONDS

EAT_OUTPUT=`script -q -e -c 'wscat -n -w 2 -x '"'"'{"message_type":"hm_get_command_queue","message":"{\"token\":\"'"'$HUB_TOKEN'"'\",\"COMMANDS\":[{\"COMMAND\":\"{'"'"'"'"'"'"'"'"'READ_DCB'"'"'"'"'"'"'"'"':100}\",\"COMMANDID\":1}]}"}'"' -c \"wss://$HUB_IP:$HUB_PORT\""`
WSCAT_OUTPUT=`sed -n 2p typescript`
WSCAT_OUTPUT=${WSCAT_OUTPUT:9}

RESPONSE_ELEM=`echo $WSCAT_OUTPUT | jq ".response"`

UPTIME_SECS=`echo $RESPONSE_ELEM | sed -E -e 's/\\\n|\\\//g' -e 's/^"//' -e 's/"$//' | jq ".UPTIME"`

date=$(TZ='Europe/Amsterdam' date '+%d-%m-%Y %H:%M:%S')
if [[ $UPTIME_SECS -lt $REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_SECONDS ]]
then
	echo "$date - Successfully restarted the NeoHub. Current uptime is $UPTIME_SECS sec. which is less than $REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_SECONDS ($REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_MINUTES min.)"
else
	echo "$date - Failed to restart the NeoHub. Current uptime is $UPTIME_SECS sec. which is greater than $REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_SECONDS ($REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_MINUTES min.)"
	push_to_mobile "NeoHub cron" "The restart cronjob failed to reboot the NeoHub (restart window of $REBOOT_VERIFICATION_UPTIME_THRESHOLD_IN_MINUTES min. expired)"
fi

#cleanup:
rm typescript
