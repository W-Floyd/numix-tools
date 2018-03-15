#!/bin/bash

if [ -d 'icons' ]; then
    rm -r 'icons'
fi

lsdir () {
    if [ -z "${1}" ]; then
        find . -maxdepth 1 -mindepth 1 -type d | sort
    else
        find "${1}" -maxdepth 1 -mindepth 1 -type d | sort
    fi
}

# __parse_shift <direction> <theme>

__parse_shift () {
    local direction="shift_${1}"
    echo "${!direction}" | sed 's/,/\n/g' | grep -E "^${2}=" | sed 's/.*=//'
}

# __icon_process <raw_line>

__icon_parse () {

eval "$(
echo "${1}" | sed -e 's/ /\n/g' -e 's#/#\n/#' | sed -e '1d' -e '$d' | while read -r __var; do
    echo "local ${__var}"
done
)"

# check for absolutely mandatory keys 
while read -r __check; do
    if [ -z "${!__check}" ]; then
        echo "Entry has no variable '${__check}' declared"
        return 1
    fi
done <<< 'name'

(
ls './templates/baseplates/' | while read -r __svg; do
    basename "${__svg}" '.svg'
done
lsdir './themed/baseplates/'
lsdir './themed/symbols/'
) | sed 's#.*/##' | sort | uniq | while read -r __theme; do

    icon_process

done

}

# icon_process

icon_process () {

local __temp_baseplate="$(mktemp --suffix '.svg')"

local __baseplate_themed="./themed/baseplates/${__theme}/${name}.svg"

local __baseplate_template="./templates/baseplates/${__theme}.svg"

if [ -e "${__baseplate_themed}" ]; then
    
    cp "${__baseplate_themed}" "${__temp_baseplate}"

elif ! [ -e "${__baseplate_template}" ]; then
    
    echo "Entry '${name}' has no baseplate options with theme '${__theme}'."
    return 2

else

    if [ -z "${baseplate_top}" ] && [ -z "${baseplate_bottom}" ]; then
        echo "Entry '${name}' has no baseplate colours declared, with no custom baseplate."
        return 3
    elif [ -z "${baseplate_top}" ]; then
        echo "Entry '${name}' has no top baseplate colour declared, with no custom baseplate."
        return 4
    elif [ -z "${baseplate_bottom}" ]; then
        echo "Entry '${name}' has no bottom baseplate colour declared, with no custom baseplate."
        return 5
    fi
    
    cp "${__baseplate_template}" "${__temp_baseplate}"
    
fi

################################################################################
# Let's check symbols now.
################################################################################

local __temp_symbol="$(mktemp --suffix '.svg')"

local __symbol_themed="./themed/symbols/${__theme}/${name}.svg"

local __symbol_template="./templates/symbols/${name}.svg"

if [ -e "${__symbol_themed}" ]; then
    
    cp "${__symbol_themed}" "${__temp_symbol}"

elif ! [ -e "${__symbol_template}" ]; then
    
    echo "Entry '${name}' has no symbol options with theme '${__theme}'."
    return 2

else
    
    cp "${__symbol_template}" "${__temp_symbol}"
    
fi

################################################################################
# Let's begin!
################################################################################

local __target_icon="./icons/${__theme}/${name}.svg"

mkdir -p "$(dirname "${__target_icon}")"

cat "${__temp_baseplate}" | sed -e '$d' -e "s/#0f0/${baseplate_bottom}/" -e "s/#f00/${baseplate_top}/" > "${__target_icon}"

local __shift_x="$(__parse_shift x "${__theme}")"
local __shift_y="$(__parse_shift y "${__theme}")"

local __shift_shadow_x="$(__parse_shift shadow_x "${__theme}")"
local __shift_shadow_y="$(__parse_shift shadow_y "${__theme}")"

if [ "${shadow}" = 'true' ] || [ "${shadow}" = '1' ] || [ "${shadow}" = 'yes' ] ; then

    (

    echo " <g transform=\"translate($((__shift_x+__shift_shadow_x)) $((-1*__shift_y+__shift_shadow_y)))\" style=\"opacity:.1\">"

    cat "${__temp_symbol}" | sed -e '1d' -e '$d' -e 's/^/ /' -e 's/stroke:#[a-e,0-9]*/stroke:#000/g' -e 's/fill:#[a-e,0-9]*/fill:#000/g'
    
    echo ' </g>'
    
    ) >> "${__target_icon}"

fi

(

echo " <g transform=\"translate($((__shift_x)) $((-1*__shift_y)))\">"

cat "${__temp_symbol}" | sed -e '1d' -e '$d' -e 's/^/ /'

echo ' </g>
</svg>'

) >> "${__target_icon}"

}

shift_x='circle=0,square=0'
shift_y='circle=0,square=1'

shift_shadow_x='circle=1,square=0'
shift_shadow_y='circle=1,square=1'

shadow=true

xmllint data_builder.xml --format --pretty 3 | sed -e '1d' | while read -r __line; do

    __icon_parse "${__line}"

done

exit
