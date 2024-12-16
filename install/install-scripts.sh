#! /bin/bash

init_config_files() {
    for i in $(pwd)/conf/*; do
        if [ ! -e "${i%.tpl}" ]; then
            cp "$i" "${i%.tpl}"
        fi
    done
}