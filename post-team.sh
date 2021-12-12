#!/bin/bash

TEAM="translators"

if [ $# -ne 2 ]; then
	echo
	echo "Usage:"
	echo "    ${0##*/} \"Title\" body.txt"
	echo
	exit 1
fi

TITLE="$1"
FILE="$2"

echo
echo -e "\e[1;36m$TITLE\e[0m"
echo
cat "$FILE"
echo

read -r -p "Post? [y/N] " -n 1 RESULT
echo
if [ "$RESULT" != "y" ]; then
	echo "Aborted"
	exit 1
fi

if gh api orgs/neomutt/teams/$TEAM/discussions --silent -f body="$(cat "$FILE")" -f title="$TITLE"; then
	echo -e "\e[1;32mSuccess\e[0m"
else
	echo -e "\e[1;31mFailed\e[0m"
fi

