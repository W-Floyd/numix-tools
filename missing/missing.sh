#!/bin/bash

__circle="$(find './icons/circle/48/' | while read -r __file; do
    echo "${__file/*\/}"
done | sort)"

__square="$(find './icons/square/48/' | while read -r __file; do
    echo "${__file/*\/}"
done | sort)"

echo "Icons not in square that are in circle
"

grep -Fxv "${__square}" <<< "${__circle}"

echo "

Icons not in circle that are in square
"

grep -Fxv "${__circle}" <<< "${__square}"

exit
