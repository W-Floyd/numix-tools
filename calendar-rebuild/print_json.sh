#!/bin/bash

while read -r __colour; do

    seq -w 01 31 | while read -r __number; do

        cat <<EOF
    "calendar-${__colour}-${__number}": {
        "linux": {
            "root": "calendar-${__colour}-${__number}"
        }
    },
EOF

    done

done <<< 'black
turquoise'

exit
