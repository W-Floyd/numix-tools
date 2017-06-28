#!/bin/bash

__icon_list=''
__exclude_list=''
__verbose='1'
__background='white'
__size=''
__default_size='256'

################################################################################
#
# ... | __funiq
#
# First uniq
# like uniq, but does not need to be sorted, and so retains ordering.
#
################################################################################

__funiq () {

cat | sed '/^$/d' | awk '!cnts[$0]++'

}

################################################################################
#
# __strip_ansi
#
# Strips ANSI codes from *piped* input.
#
################################################################################

__strip_ansi () {
cat | perl -pe 's/\e\[?.*?[\@-~]//g'
}

################################################################################
#
# __print_pad
#
# Prints the given number of spaces.
#
################################################################################

__print_pad () {
seq 1 "${1}" | while read -r __line; do
    echo -n ' '
done
}

################################################################################
#
# __format_text <LEADER> <TEXT> <TRAILER>
#
# Pads text to a set length, so multiline warnings, info and errors can be made.
#
################################################################################

__format_text () {
echo -ne "${1}"
local __desired_size='7'
local __leader_size="$(echo -ne "${1}" | __strip_ansi | wc -m)"
local __clipped_size=$((__desired_size-__leader_size-3))
local __front_pad="$(__print_pad "${__clipped_size}") - "
echo -ne "${__front_pad}"
local __pad=''

if [ "$(wc -l <<< "${2}")" -gt '1' ]; then
    head -n -1 <<< "${2}" | while read -r __line; do
        if [ -z "${__pad}" ]; then
            echo -e "${__pad}${__line}"
            local __pad="$(__print_pad "${__desired_size}")"
        else
            echo -e "${__pad}${__line}"
        fi
    done
    local __pad="$(__print_pad "${__desired_size}")"
    echo -e "${__pad}$(tail -n 1 <<< "${2}")${3}"
else
    echo -e "${2}${3}"
fi

}

################################################################################
#
# __custom_error <MESSAGE>
#
# Custom Error
# Echos an error statement without quiting.
#
################################################################################

__custom_error () {
__format_text "\e[31mERRO\e[39m" "${1}" "${2}" 1>&2
}

################################################################################
#
# __error <MESSAGE>
#
# Error
# Echos a statement when something has gone wrong, then exits.
#
################################################################################

__error () {
__custom_error "${1}" ", exiting."
exit 1
}

################################################################################
#
# __force_warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong.
#
################################################################################

__force_warn () {
__format_text "\e[93mWARN\e[39m" "${1}" ", continuing anyway." 1>&2
}

################################################################################
#
# __force_announce <MESSAGE>
#
# Force Announce
# Echos a statement, when __quiet is equal to 0.
#
################################################################################

__force_announce () {
__format_text "\e[32mINFO\e[39m" "${1}" ""
}

################################################################################
#
# __announce <MESSAGE>
#
# Announce
# Echos a statement, only if __verbose is equal to 1.
#
################################################################################

__announce () {
if [ "${__verbose}" = '1' ]; then
    __force_announce "${1}"
fi
}

################################################################################
#
# <LIST_OF_FILES> | __mext <FILE_1> <FILE_2> <FILE_3> ...
#
# Minus Extension
# Strips last file extension from string.
#
################################################################################

__mext () {

__tmp_mext_sub () {
    echo "${1%.*}"
}

while ! [ "${#}" = '0' ]; do
    __tmp_mext_sub "${1}"
    shift
done

if read -r -t 0; then
    cat | while read -r __value; do
        __tmp_mext_sub "${__value}"
    done
fi

}

################################################################################
#
# __custom_tile <FILE1> <FILE2> ... <GRID> <SPACER> <OUTPUT>
#
# Custom Tile
# Tiles images. Takes input files. Third last option is grid
# (e.g. '2x3'), second last is the spacer (e.g. '2'), last is
# the output image.
#
# Example:
# __custom_tile dirt.png grass.png plank.png plank.png 2x2 1 mash.png
#
################################################################################

__custom_tile () {

if [ "${#}" -lt '4' ]; then
    __error "Not enough options specified for __custom_tile"
fi

__num_sub () {
__option_num="$((__option_num-1))"
}

local __option_num="${#}"

local __output="${!__option_num}"
__num_sub
local __spacer="${!__option_num}"
__num_sub
local __grid="${!__option_num}"
__num_sub

local __imgseq="$(for __num in $(seq 1 "${__option_num}"); do echo -n "${!__num} "; done)"

montage -geometry "+${__spacer}+${__spacer}" -background "${__background}" -tile "${__grid}" ${__imgseq} "${__output}" 2> /dev/null

if ! [ -e "${__output}" ]; then
    __force_warn "File \"${__output}\" was not produced when custom tiling"
fi

}

################################################################################

__usage () {
echo "$(basename "${0}") <OPTIONS> <ICONS>

Makes a labeled icon montage for Numix PRs.

Options:
  -h  -? --help             Help (this message).
  -v  --verbose             Be verbose (default).
  -q  --quiet               Don't be verbose.

  --exclude=<theme>         Icon themes to exclude from compositing.
                            May be specified multiple times.

  --background=<colour>     Background colour to use.

  --size=<size>             Minimum size to scale icons to.
"
}

################################################################################

# If there are are options,
if ! [ "${#}" = 0 ]; then

################################################################################

__check_input () {

case "${1}" in

    "-h" | "-?" | "--help")
        __usage
        exit 77
        ;;

    "-v" | "--verbose")
        __verbose='1'
        ;;

    "-q" | "--quiet")
        __verbose='0'
        ;;

    "--exclude="*)
        __add_flag "${1}" __exclude_list
        ;;

    "--background="*)
        __set_flag "${1}" __background
        ;;

    "--size="*)
        __set_flag "${1}" __size
        ;;

    *)
        __icon_list+="
${1}"
        ;;

esac

}

################################################################################

__process_option () {

if [ "${1}" = '-' ] || [ "${1}" = '--' ]; then

    __check_input "${1}"

elif grep '^--.*' <<< "${1}" &> /dev/null; then

    __check_input "${1}"

elif grep '^-.*' <<< "${1}" &> /dev/null; then

    __letters="$(cut -c 2- <<< "${1}" | sed 's/./& /g')"

    for __letter in ${__letters}; do

        __check_input "-${__letter}"

    done

else
    __check_input "${1}"
fi

if [ "${?}" = '77' ]; then
    exit
fi

}

################################################################################

__check_option () {
if grep -q '^-.*' <<< "${1}"; then
    return 0
else
    return 1
fi
}

################################################################################
#
# __set_flag <RAW_OPTION> <VARIABLE>
#
# Set Flag
# Sets a flag from RAW_OPTION in VARIABLE.
#
################################################################################

__set_flag () {
export "${2}"="$(sed 's/[^=]*=//' <<< "${1}")"
}

################################################################################
#
# __add_flag <RAW_OPTION> <VARIABLE>
#
# Add Flag
# Adds a flag from RAW_OPTION onto VARIABLE.
#
################################################################################

__add_flag () {
export "${2}"+="
$(sed 's/[^=]*=//' <<< "${1}")"
}

################################################################################

# then let's look at them in sequence.
while ! [ "${#}" = '0' ]; do

    case "${__last_option}" in

        *)
            __process_option "${1}"
            ;;

    esac

    __last_option="${1}"

    shift

done

fi

__last_option=''

################################################################################

if ! [ -d 'original' ] || ! [ -d '../icons' ]; then
    __error "Not in the numix directory"
fi

if [ -z "${__icon_list}" ]; then
    __error "No icons specified"
fi

################################################################################

sed '/^$/d' <<< "${__icon_list}" | while read -r __icon; do

    __announce "Processing '${__icon}'"

    if [ -z "${__size}" ]; then
        __size="${__default_size}"
    fi

    __tmp_dir="$(mktemp -d)"
    __original="./original/${__icon}"
    __font='Ubuntu'
    __orig_target=''

    if ! grep -qx "original" <<< "${__exclude_list}"; then

        if [ -e "${__original}.svg" ]; then

            rsvg-convert "${__original}.svg" -w "${__size}" -o "${__original}.png"

        fi

        if [ -e "${__original}.png" ]; then
            __orig_target="${__original}.png"
        elif [ -e "${__original}.jpg" ]; then
            __orig_target="${__original}.jpg"
        fi

        if [ -e "${__orig_target}" ] ; then
            until ! [ "$(identify -format "%w" "${__orig_target}")" -lt "${__size}" ]; do
                convert "${__orig_target}" -scale 200% "${__orig_target}"
            done
            __size="$(identify -format "%w" "${__orig_target}")"
            montage -font "${__font}" -label "Original" "${__orig_target}" -geometry +0+0 -background "${__background}" "${__tmp_dir}/original.png"
        fi

    fi

    find ../icons/ | grep -E "/${__icon}.svg\$" | while read -r __file; do

        __theme="$(sed 's#^../icons/\([^/]*\).*#\1#' <<< "${__file}")"

        if ! grep -qx "${__theme}" <<< "${__exclude_list}"; then

            __tmp_file="$(mktemp --suffix=.png "--tmpdir=${__tmp_dir}")"

            rsvg-convert "${__file}" -w "${__size}" -o "${__tmp_file}"

            montage -font "${__font}" -label "${__theme^}" "${__tmp_file}" -geometry +0+0 -background "${__background}" "${__tmp_dir}/${__theme}.png"

            rm "${__tmp_file}"

        fi

    done

    __num_file="$(find "${__tmp_dir}" -type f | wc -l)"

    __files="$(
    (
    echo "original
circle
square" | sed -e "s#^#${__tmp_dir}/#" -e 's#$#\.png#' | grep "$(find "${__tmp_dir}" -type f | sed 's#.*/\([^\.]*\)*\.png#\1#')"
    find "${__tmp_dir}" -type f
    ) | __funiq | while read -r __file; do
        echo -n "${__file} "
    done | sed 's/ $//'
    )"

    __custom_tile "${__files}" "${__num_file}x1" 8 "./iconified_${__icon}.png"

    optipng "./iconified_${__icon}.png" -quiet

    rm -r "${__tmp_dir}"

done

exit
