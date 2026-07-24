#!/bin/bash

# Usage:
# 	plist-array-remove.sh <list-key-name> <element> <plist-path>

# Test Cases:
# Case 1: Array key not found - error. Need better error message.
# Case 2: Element key not found - ok.
# Case 3: Element key found - ok.

LIST_KEY_NAME=$1
ELEMENT=$2
PLIST_PATH=$3

if [ $# -ne 3 ]; then
  echo "Usage: ./plist-array-remove.sh <list-key-name> <element> <plist-path>"
  exit 1
fi

if ! plutil -extract "$LIST_KEY_NAME" xml1 -o /dev/null "$PLIST_PATH"; then
	echo "Array not found: $LIST_KEY_NAME"
	exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Print :\"${LIST_KEY_NAME}\"" "${PLIST_PATH}" | grep -q "${ELEMENT}"; then
	echo "Not present: $ELEMENT"

else
	echo "Removing: $ELEMENT"
	index=0
	while true; do
		value=$(/usr/libexec/PlistBuddy -c "Print :\"${LIST_KEY_NAME}\":${index}" "${PLIST_PATH}" 2>/dev/null) || break
		if [ "$value" = "$ELEMENT" ]; then
			/usr/libexec/PlistBuddy -c "Delete :\"${LIST_KEY_NAME}\":${index}" "${PLIST_PATH}"
			exit 0
		fi
		index=$((index + 1))
	done
	echo "Could not find: $ELEMENT"
	exit 1
fi
