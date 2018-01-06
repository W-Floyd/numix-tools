#!/bin/bash

ask() {
    # https://djm.me/ask
    local prompt default reply

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

__workspace_offset='1'
__tmp_dir="$(mktemp -d)"
__script_dir="${__tmp_dir}/script"
__script_file="${__script_dir}/inkscape.lua"
mkdir "${__script_dir}"

__width="$(xdpyinfo | grep dimension | sed -e 's/.*: *\([^ ]*\).*/\1/' -e 's/x.*//')"

cat <<EOF > "${__script_file}"
if (get_application_name()=="inkscape") then

    debug_print(get_window_name())

    if string.match(get_window_name(), "square_") then
        debug_print("Right")
        set_window_geometry($((__width/2)),0,$((__width/2)),1000);
    elseif string.match(get_window_name(), "circle_") then
        debug_print("Left")
        set_window_geometry(0,0,$((__width/2)),1000);
    end

    set_window_workspace($((__workspace_offset+1)));

    maximize_vertically();
end
EOF

# cat <<EOF > "${__script_file}"
# if (get_application_name()=="inkscape") then

#     debug_print(get_window_name())

#     if string.match(get_window_name(), "square_") then
#         debug_print("Right")
#         set_window_geometry($((__width/2)),0,$((__width/2)),1000);
#     elseif string.match(get_window_name(), "circle_") then
#         debug_print("Left")
#         set_window_geometry(0,0,$((__width/2)),1000);
#     end

#     if string.match(get_window_name(), "original.svg") then
#         debug_print("Top")
#         set_window_workspace($((__workspace_offset+1)));
#     elseif string.match(get_window_name(), "new.svg") then
#         debug_print("Bottom")
#         set_window_workspace($((__workspace_offset+2)));
#     end

#     maximize_vertically();
# end
# EOF

__new_square_source='templates/square/48.svg'
__new_circle_source='templates/circle/48.svg'

devilspie2 --folder="${__script_dir}" &> /dev/null &

echo "Create file 'haltfile' to prevent further runs."
touch 'clean_list'

{

find icons/circle/48/ -type f
find icons/square/48/ -type f

} | sed -e 's/^.*\///' -e 's/\.svg$//' | sort | uniq | grep -Fxvf 'clean_list' | grep -Fxvf 'cleaned_list' | grep -Fxvf 'redesign' | while read -r __name; do

    if [ -e haltfile ]; then
        echo 'Okay, I will stop now.'
        exit
    fi

    echo "${__name}"

    __new_square="${__tmp_dir}/square_new.svg"
#    __old_square="${__tmp_dir}/square_original.svg"
    __old_square_source="icons/square/48/${__name}.svg"
#    __new_circle="${__tmp_dir}/circle_new.svg"
    __old_circle="${__tmp_dir}/circle_original.svg"
    __old_circle_source="icons/circle/48/${__name}.svg"

    __pid=()

    # if [ -e "${__old_square_source}" ]; then
    #     cp "${__old_square_source}" "${__old_square}"
    #     inkscape "${__old_square}" &
    #     __pid+=("${!}")
    # fi

    if [ -e "${__old_circle_source}" ]; then
        cp "${__old_circle_source}" "${__old_circle}"
        inkscape "${__old_circle}" &
        __pid+=("${!}")
    fi

#    cp "${__new_circle_source}" "${__new_circle}"
    cp "${__new_square_source}" "${__new_square}"

    inkscape "${__new_square}" &
    __pid+=("${!}")

    # inkscape "${__new_circle}" &
    # __pid+=("${!}")

    wait ${__pid[@]}

    if ! [ "$(md5sum < "${__new_square_source}")" == "$(md5sum < "${__new_square}")" ]; then
        mv "${__new_square}" "${__old_square_source}"
    fi

    # if ! [ "$(md5sum < "${__new_circle_source}")" == "$(md5sum < "${__new_circle}")" ]; then
    #     mv "${__new_circle}" "${__old_circle_source}"
    # fi

    __changed="$(git diff --name-only icons/)"

    # if grep -q 'icons/circle/48/' <<< "${__changed}" && grep -q 'icons/square/48/' <<< "${__changed}"; then
    #     __message="${__name}: Clean and optimize circle and square."
    # elif grep -q 'icons/circle/48/' <<< "${__changed}"; then
    #     __message="${__name}: Clean and optimize circle."
    # elif grep -q 'icons/square/48/' <<< "${__changed}"; then
    if grep -q 'icons/square/48/' <<< "${__changed}"; then
        __message="${__name}: Clean and optimize square."
    fi

    if ! [ -z "${__changed}" ]; then

        git add icons
        git commit --no-gpg-sign -m "${__message}" &> /dev/null

        echo 'Marked as cleaned'
        echo "${__name}" >> 'cleaned_list'

    else

        echo 'No changes detected.'

        if ask 'Was the design up to snuff?'; then
            echo 'Marked as clean'
            echo "${__name}" >> 'clean_list'
        else
            echo 'Marked for redesign.'
            echo "${__name}" >> 'redesign'
        fi

    fi

done

rm "${__script_file}"

rm -r "${__tmp_dir}"

exit