#!/bin/bash

# Assumes a folder named 'base' exists, and holds files with 'red' in their name
# Replaces the base red colours with the ones set in here. Customize as needed.
#
# Used to recolour calendar files, mostly.

if [ -d 'recolour' ]; then
    rm -r 'recolour'
fi

mkdir 'recolour'

# __recolour <FILE> <COLOUR> <MAIN> <SHADOW>
__recolour () {
local __file="${1}"
shift
local __goal="./recolour/$(sed "s/red/${1}/" <<< "${__file}")"
cp "./base/${__file}" "${__goal}"
sed -i -e "s/#d64936/#${2}/" -e "s/#7f2c20/#${3}/" "${__goal}"
}

ls ./base/ | while read -r __file; do

    __recolour "${__file}" 'blue' '3685d6' '20517f'

    __recolour "${__file}" 'purple' '6c59a6' '362f70'

done

exit
