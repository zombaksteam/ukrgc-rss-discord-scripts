#!/bin/bash

# (c) Zombak, 2020
# For UrkGameCommunity
# https://steamcommunity.com/profiles/76561198078585952/
# https://www.ukrgc.com.ua/?feed=rss2

# HOW TO USE:
# Set Discord bot name and hook url
# Set news RSS feed link
# Set cron job to run this script every 1/5 minutes

CONST_DISCORD_BOT_NAME="UKR'GC News Bot"
CONST_DISCORD_HOOK_URL="https://discordapp.com/api/webhooks/692060125644587108/YOUR_DISCORD_HOOK_KEY"
CONST_STEAM_GROUP_FEED="https://www.ukrgc.com.ua/?feed=rss2"

CONST_SCRIPT_DIR="$(dirname "$0")"
CONST_FILE_POSTED_NEWS="${CONST_SCRIPT_DIR}/posted-news.txt"

if [ ! -f "${CONST_FILE_POSTED_NEWS}" ]; then
	/usr/bin/touch ${CONST_FILE_POSTED_NEWS}
fi

FUNC_NOTICE() {
	LOCAL_MSG_TO_SEND="$1"
	/usr/bin/curl -H "Content-Type: application/json" -X POST \
		-d "{\"username\": \"${CONST_DISCORD_BOT_NAME}\", \"content\": \"${LOCAL_MSG_TO_SEND}\"}" \
		${CONST_DISCORD_HOOK_URL}
}

FUNC_LOAD_FEED() {
	LOCAL_FEED_DATA=$(/usr/bin/curl -k --silent "${CONST_STEAM_GROUP_FEED}")
	LOCAL_FEED_DATA=$(/bin/echo "${LOCAL_FEED_DATA}" | tr '\n' ' ')
	LOCAL_ITEM=$(/bin/grep -oP "(?<=<item>).*?(?=</item>)" <<< "${LOCAL_FEED_DATA}")
	/bin/echo "${LOCAL_ITEM}"
}

FUNC_POST_NEW_TO_DIS() {
	LOCAL_ITEM_TITLE="$1"
	LOCAL_ITEM_LINK="$2"
	LOCAL_MESSAGE="\`\`\`${LOCAL_ITEM_TITLE}\`\`\`\n${LOCAL_ITEM_LINK}"
	FUNC_NOTICE "${LOCAL_MESSAGE}"
}

FUNC_EVENT_FEED_ITEM() {
	LOCAL_ITEM_TITLE="$1"
	LOCAL_ITEM_LINK="$2"
	LOCAL_IS_POSTED=$(/bin/cat ${CONST_FILE_POSTED_NEWS} | /bin/grep "${LOCAL_ITEM_LINK}")
	if [[ $LOCAL_IS_POSTED == "" ]]; then
		FUNC_POST_NEW_TO_DIS "${LOCAL_ITEM_TITLE}" "${LOCAL_ITEM_LINK}"
		/bin/echo "${LOCAL_ITEM_LINK}" >> ${CONST_FILE_POSTED_NEWS}
		/bin/sleep 1
	fi
}

if [[ $CONST_DISCORD_HOOK_URL != "" ]]; then
	FUNC_LOAD_FEED | /usr/bin/tac | while read ITEM
	do
		LOCAL_ITEM_TITLE=$(/bin/grep -oP "(?<=<title>).*?(?=</title>)" <<< "${ITEM}")
		LOCAL_ITEM_LINK=$(/bin/grep -oP "(?<=<link>).*?(?=</link>)" <<< "${ITEM}")
		if [[ $LOCAL_ITEM_TITLE != "" ]] && [[ $LOCAL_ITEM_LINK != "" ]]; then
			FUNC_EVENT_FEED_ITEM "${LOCAL_ITEM_TITLE}" "${LOCAL_ITEM_LINK}"
		else
			/bin/echo "Error, something is not set, item title or item link!"
		fi
	done
else
	/bin/echo "Error, Steam RSS feed url is not set!"
fi
