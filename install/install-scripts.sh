#! /bin/bash

# Copy a template to its target if the target doesn't exist yet
copy_template() {
    local tpl="$1"
    local target="${tpl%.tpl}"
    if [ ! -e "$target" ]; then
        cp "$tpl" "$target"
        echo "Created $target"
    fi
}

init_config_files() {
    local root="${DIR:-$(pwd)}"
    for i in "$root"/conf/*.tpl; do
        [ -f "$i" ] && copy_template "$i"
    done
}
