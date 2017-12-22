#!/bin/bash

make_number_sane () {
    printf "%f\n" "$(cat)" | sed -e 's/0*$//' -e 's/\.$//'
}

while read -r __theme; do

    if [ -d "${__theme}" ]; then
        rm -r "${__theme}"
    fi

    mkdir "${__theme}"

done <<< 'output
output/circle
output/square'

__symbol_pointer='<!-- Symbol Replace -->'

seq -w 01 31 | while read -r __number; do

    __symbol="$(sed -e '1,25d' -e 's/opacity:.12/opacity:.10/' -e '$d' -e 's/\//\\\//g' < "stock/square/calendar-red-${__number}.svg")"

    __existing_y_translate="$(grep 'transform="matrix(' <<< "${__symbol}" | sed -e '2!d' -e 's/^.*(\(.*\)).*/\1/' | cut -d' ' -f6 | make_number_sane)"
    __existing_y_translate_shadow="$(grep 'transform="matrix(' <<< "${__symbol}" | sed -e '1!d' -e 's/^.*(\(.*\)).*/\1/' | cut -d' ' -f6 | make_number_sane)"
    __existing_x_translate_shadow="$(grep 'transform="matrix(' <<< "${__symbol}" | sed -e '1!d' -e 's/^.*(\(.*\)).*/\1/' | cut -d' ' -f5 | make_number_sane)"

    __main_matrix_line_number="$(grep 'transform="matrix(' -n <<< "${__symbol}" | cut -f1 -d: | sed -e '2!d')"

    __shadow_matrix_line_number="$(grep 'transform="matrix(' -n <<< "${__symbol}" | cut -f1 -d: | sed -e '1!d')"

    while read -r __line; do

        __theme="$(cut -d' ' -f1 <<< "${__line}")"
        __y_translate="$(cut -d' ' -f2 <<< "${__line}")"
        __x_translate_shadow="$(cut -d' ' -f3 <<< "${__line}")"
        __template_file="output/${__theme}/calendar-template-${__number}.svg"

        __new_y_translate="$(bc <<< "${__existing_y_translate}+${__y_translate}")"
        __new_y_translate_shadow="$(bc <<< "${__existing_y_translate_shadow}+${__y_translate}")"
        __new_x_translate_shadow="$(bc <<< "${__existing_x_translate_shadow}+${__x_translate_shadow}")"

        __translated_symbol="$(sed -e "${__main_matrix_line_number}s/matrix(\(.*\) [^ ]*)/matrix(\1 ${__new_y_translate})/" -e "${__shadow_matrix_line_number}s/matrix(\(.*\) [^ ]* [^ ]*)/matrix(\1 ${__new_x_translate_shadow} ${__new_y_translate_shadow})/" <<< "${__symbol}")"

        perl -0pe "s/<!-- Symbol Pointer -->/${__translated_symbol}/" < "${__theme}.svg" > "${__template_file}"

        while read -r __recolour; do

            __colour_name="$(cut -d' ' -f1 <<< "${__recolour}")"
            __main_colour="$(cut -d' ' -f2 <<< "${__recolour}")"
            __shade_colour="$(cut -d' ' -f3 <<< "${__recolour}")"

            __output="output/${__theme}/calendar-${__colour_name}-${__number}.svg"

            sed -e "s/#f00/#${__main_colour}/g" -e "s/#ff0/#${__shade_colour}/g" < "${__template_file}" > "${__output}"

        done <<< 'red d64936 7f2c20
purple 6c59a6 362f70
blue 3685d6 20517f
turquoise 4fc7b7 456060
black 404040 282828'
# <colour_name> <main_colour> <shade_colour>

        rm "${__template_file}"

    done <<< 'circle 1 1
square 0 0'
# <theme> <y_translate> <x_translate_shadow>

done

exit
