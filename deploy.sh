#!/bin/bash

set -o errexit	# set -e
set -o nounset	# set -u

function calc_percentage()
{
	local FILE="$1"
	local TNUM=0
	local FNUM=0
	local UNUM=0
	local LINE

	LINE="$(msgfmt --statistics -c -o /dev/null "$FILE" 2>&1 | sed 's/ \(message\|translation\)s*\.*//g')"

	# filename: 104 translated, 22 fuzzy, 11 untranslated
	if [[ "$LINE" =~ ([0-9]+)[[:space:]]translated,[[:space:]]([0-9]+)[[:space:]]fuzzy,[[:space:]]([0-9]+)[[:space:]]untranslated ]]; then
		TNUM=${BASH_REMATCH[1]} # translated
		FNUM=${BASH_REMATCH[2]} # fuzzy
		UNUM=${BASH_REMATCH[3]} # untranslated
	# filename: 320 translated, 20 untranslated
	elif [[ "$LINE" =~ ([0-9]+)[[:space:]]translated,[[:space:]]([0-9]+)[[:space:]]untranslated ]]; then
		TNUM=${BASH_REMATCH[1]} # translated
		UNUM=${BASH_REMATCH[2]} # untranslated
	# filename: 5 translated, 13 fuzzy
	elif [[ "$LINE" =~ ([0-9]+)[[:space:]]translated,[[:space:]]([0-9]+)[[:space:]]fuzzy ]]; then
		TNUM=${BASH_REMATCH[1]} # translated
		FNUM=${BASH_REMATCH[2]} # fuzzy
	# filename: 63 translated
	elif [[ "$LINE" =~ ([0-9]+)[[:space:]]translated ]]; then
		TNUM=${BASH_REMATCH[1]} # translated
	fi

	# number of translated strings
	local TOTAL=$((TNUM+FNUM+UNUM))
	# percentage complete
	echo $((100*TNUM/TOTAL))
}


NEOMUTT_DIR="$1"
WEBSITE_DIR="$2"
WEBSITE_FILE="$3"

echo "NEOMUTT_DIR  = $NEOMUTT_DIR"
echo "WEBSITE_DIR  = $WEBSITE_DIR"
echo "WEBSITE_FILE = $WEBSITE_FILE"
echo "GITHUB_REF   = $GITHUB_REF"
echo "GITHUB_SHA   = $GITHUB_SHA"

if [ "$GITHUB_REF" != "refs/heads/translate" ]; then
	echo "This isn't branch 'translate'.  Done."
	exit 0
fi

pushd "$NEOMUTT_DIR"
FILES="$(git diff --name-only "$GITHUB_SHA^..$GITHUB_SHA" -- 'po/*.po')"
FILE_COUNT="$(echo "$FILES" | wc -w)"

if [ "$FILE_COUNT" = 1 ]; then
	AUTHOR="$(git log -n1 --format="%aN" "$GITHUB_SHA")"
	PO="${FILES##*/}"
	PO="${PO%.po}"
	PCT=$(calc_percentage "$FILES")
	MESSAGE="$AUTHOR, $PO, $PCT%"
else
	MESSAGE="update leaderboard"
fi
popd

pushd "$WEBSITE_DIR"
git add "$WEBSITE_FILE"
git commit -m "[AUTO] translation: $MESSAGE" -m "[ci skip]"
git push origin
popd

