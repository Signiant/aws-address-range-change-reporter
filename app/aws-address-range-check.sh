#!/bin/bash

INST_DIR=/app
CURRENT_JSON=${INST_DIR}/current.json
PREVIOUS_JSON=${INST_DIR}/previous.json

AWS_ADDRESS_URL=https://ip-ranges.amazonaws.com/ip-ranges.json

SLACK_TEMPLATE=${INST_DIR}/slack-template.json

CURL=/usr/bin/curl

# get the previous run file if it exists
aws s3 cp ${S3_PREV_RUN_FILE} ${PREVIOUS_JSON}

# get the json address list
$CURL -s ${AWS_ADDRESS_URL} > ${CURRENT_JSON}
RESULT=$?

if [ $RESULT -eq 0 ]; then
	if [ -e "${PREVIOUS_JSON}" ]; then
		# This is not our first run
		PREVIOUS_MODIFIED_TIME=$(cat ${PREVIOUS_JSON} | jq -r '.["createDate"]')
		CURRENT_MODIFIED_TIME=$(cat ${CURRENT_JSON} | jq -r '.["createDate"]')

		if [ "${PREVIOUS_MODIFIED_TIME}" != "${CURRENT_MODIFIED_TIME}" ]; then
			SLACK_MESSAGE_BODY=$(diff ${CURRENT_JSON} ${PREVIOUS_JSON} |grep -e 'ip_prefix' -e 'region' -e 'service' -e 'createDate' -e '{' |sed -e 's/>\s*{//g;s/>/REMOVED/g;s/</ADDED/g;s/"//g;s/,//g' |sed  ':a;N;$!ba;s/\n/\\n/g')

			cat ${SLACK_TEMPLATE} |
				jq --arg channel ${SLACK_CHANNEL} \
				   --arg message_body "${SLACK_MESSAGE_BODY}" \
				   --arg user "${WEBHOOK_USER}" \
					'.["channel"] = $channel|.["username"] = $user|.["attachments"][0]["fields"][0]["value"] = $message_body' > /tmp/slack1.$$

			cat /tmp/slack1.$$ | sed -e 's/\\n/n/g' > /tmp/slack2.$$
		fi
	else
		SLACK_MESSAGE="Inital run of the AWS address range checker. Baseline taken"
		echo ${SLACK_MESSAGE}
	fi

  # Put the current run file in S3 for retrieval next run
  aws s3 cp ${CURRENT_JSON} ${S3_PREV_RUN_FILE}
else
	SLACK_MESSAGE="ERROR Unable to download the AWS address range json"
	echo ${SLACK_MESSAGE}
fi

if [ ! -z "${SLACK_MESSAGE}" ]; then
	$CURL -s -X POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"${WEBHOOK_USER}\", \"text\": \"<!channel>  ${SLACK_MESSAGE}\"}" ${WEBHOOK_ENDPOINT}
elif [ -e /tmp/slack2.$$ ]; then
	curl -s -X POST --data-urlencode "payload=`cat /tmp/slack2.$$`" ${WEBHOOK_ENDPOINT}
	rm -f /tmp/slack?.$$
else
	echo "no slack message to post"
fi
