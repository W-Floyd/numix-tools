#!/bin/bash

while read -r __name; do
    if ! which "${__name}" &> /dev/null; then
        echo "You need ${__name} installed"
        exit 1
    fi
done <<< 'parallel
rsvg-convert
composite'

mkdir -p ignore/visualdiff/original/circle
mkdir -p ignore/visualdiff/original/square

process_image () {
    __file="${!#}"
    __name="$(sed -e 's/^.*\/\(.*\).svg$/\1/' <<< "${__file}")"
    __output="ignore/visualdiff/${1}/${2}/${__name}.png"
    if ! [ -e "${__output}" ]; then
        echo "${__name}"
        rsvg-convert "${__file}" --zoom=2 -o "${__output}"
    fi
}

process_original () {
    process_image original "${@}"
}

compare_image () {
    __file="${!#}"
    __name="$(sed -e 's/^.*\///' <<< "${__file}")"
    __output="ignore/visualdiff/transdiff/${__name}"
    if [ -e "ignore/visualdiff/translated/circle/${__name}" ] && [ -e "ignore/visualdiff/translated/square/${__name}" ] && ! [ -e "${__output}" ]; then
        composite "ignore/visualdiff/translated/circle/${__name}" "ignore/visualdiff/translated/square/${__name}" -compose difference "${__output}"
    fi
}

translate_image () {
    __file="${!#}"
    __name="$(sed -e 's/^.*\///' <<< "${__file}")"
    __output="ignore/visualdiff/translated/${1}/${__name}"
    if ! [ -e "${__output}" ]; then
        case "${1}" in
            "circle")
                convert "${__file}" -background none -gravity south -splice 0x1 "${__output}"
                ;;

            "square")
                convert "${__file}" -background none -gravity north -splice 0x1 "${__output}"
                ;;
        esac
    fi
}

export -f process_image process_original compare_image translate_image

while read -r __theme; do

    find "icons/${__theme}/48/" -type f | sort | parallel -j10 process_original "${__theme}"

done <<< 'circle
square'

mkdir -p ignore/visualdiff/translated/circle
mkdir -p ignore/visualdiff/translated/square

while read -r __theme; do

    find "ignore/visualdiff/original/${__theme}/" -type f | sort | parallel -j10 translate_image "${__theme}"

done <<< 'circle
square'

mkdir -p ignore/visualdiff/transdiff

while read -r __theme; do

    find "ignore/visualdiff/translated/${__theme}/" -type f | sort | parallel -j10 compare_image

done <<< 'circle
square'

exit
