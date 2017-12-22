#!/bin/bash

mkdir -p diff/original/circle
mkdir -p diff/original/square

process_image () {
    __file="${!#}"
    __name="$(sed -e 's/^.*\/\(.*\).svg$/\1/' <<< "${__file}")"
    __output="diff/${1}/${2}/${__name}.png"
    if ! [ -e "${__output}" ]; then
        echo "${__name}"
        rsvg-convert "${__file}" --zoom=2 -o "${__output}"
    fi
}

process_new () {
    process_image new "${@}"
}

process_original () {
    process_image original "${@}"
}

compare_image () {
    __file="${!#}"
    __name="$(sed -e 's/^.*\///' <<< "${__file}")"
    composite "diff/new/${1}/${__name}" "diff/original/${1}/${__name}" -compose difference "diff/compare/${1}/${__name}"
}

export -f process_image process_new process_original compare_image

while read -r __theme; do

    find "stock/${__theme}/" -type f | sort | parallel -j10 process_original "${__theme}"

done <<< 'circle
square'

mkdir -p diff/new/circle
mkdir -p diff/new/square

while read -r __theme; do

    find "output/${__theme}/" -type f | sort | parallel -j10 process_new "${__theme}"

done <<< 'circle
square'

mkdir -p diff/compare/circle
mkdir -p diff/compare/square

while read -r __theme; do

    find "diff/original/${__theme}/" -type f | sort | parallel -j10 compare_image "${__theme}"

done <<< 'circle
square'

exit
