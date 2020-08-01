#!/bin/bash
# set +euo pipefail
# source ./logr.bash
# logr start
set -euo pipefail

INDEX_DIR="$HOME/.gofzdoc/cache"
# See: https://stackoverflow.com/a/9107028
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P)/$(basename "${BASH_SOURCE[0]}")"
GOFZDOC_ENABLE_PREVIEW_WRAP=${GOFZDOC_ENABLE_PREVIEW_WRAP:-0}
GOFZDOC_ENABLE_PREVIEW_BAT=${GOFZDOC_ENABLE_PREVIEW_BAT:-0}

function get_pkg_and_symbol() {
    # Quoting a regex in [[  ]] may break, so should always store it in a variable,
    # then reference _unquoted_ in the conditional.
    # See: http://mywiki.wooledge.org/BashGuide/Patterns
    m_with_keyword='(.+) (func|type|const|var) ([a-zA-Z0-9_]+)[ \(]' 
    m_const_or_var_no_keyword='(.+) [[:space:]]+([a-zA-Z0-9_]+) '
    m_method='(.+) func \([a-zA-Z0-9_]+ \*?([a-zA-Z0-9_]+)\) ([a-zA-Z0-9_]+)\('
    if [[ "$1" =~ $m_with_keyword ]]; then
        echo "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}"
    elif [[ "$1" =~ $m_const_or_var_no_keyword ]]; then
        echo "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    elif [[ "$1" =~ $m_method ]]; then
        echo "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"."${BASH_REMATCH[3]}"
    else
        echo 'pattern not implemented'
    fi
}

# Executes command given by $1, applies filters, and echos output to stdout.
# $2 is prepended to each line.
function gofzdoc_filter() {
    # Get vars and consts
    eval $1 | grep -E '^[[:space:]]*[a-zA-Z0-9_]+\s+(.+)?=' | sed -E "s|.*|$2 &|" || true
    # Get types
    eval $1 | grep -E '^type' | sed -E "s|.*|$2 &|" || true
    # Get funcs
    eval $1 | grep -E '^func' | sed -E "s|.*|$2 &|" || true
}

# Builds index for version number supplied by $1
function gofzdoc_build_index() {
    cache=${INDEX_DIR}/${1}.txt
    mkdir -p ${INDEX_DIR}
    > "$cache"

    pkgs=()
    oldIFS="$IFS"
    IFS=$'\n' pkgs=($(go list std))
    IFS="$oldIFS"

    num_pkgs=${#pkgs[@]}
    i=1
    echo
    for pkg in "${pkgs[@]}"
    do
        echo -en "\rScanning package $i/$num_pkgs"
        gofzdoc_filter "go doc -all $pkg" "$pkg" >> "$cache"
        ((i++))
    done
    echo
    echo "Index built."
}

# Builds index from the go.mod file in the current directory.
function gofzdoc_build_mod_index() {
    out=$(cksum go.mod)
    sum=${out%% *}
    cache=${INDEX_DIR}/${sum}.txt
    mkdir -p ${INDEX_DIR}
    > "$cache"

    allpkgs=()
    mods=()
    oldIFS="$IFS"
    IFS=$'\n' allpkgs=($(go list ...))
    IFS=$'\n' mods=($(go list -m all))
    IFS="$oldIFS"

    # Get mod identifiers; strip off version info
    for ((i = 0; i < ${#mods[@]}; i++)); do
        mods[i]="${mods[i]%% *}"
    done

    # Doesn't seem to be a way to list all packages depended on by the
    # main/current module via the `go list` command, so instead we'll get
    # all packages on the system, and filter for the ones that are in modules
    # listed in go.mod.
    pkgs=()
    for pkg in "${allpkgs[@]}"; do
        for mod in "${mods[@]}"; do
            if [[ "$pkg" =~ "$mod" ]]; then
                pkgs+=("$pkg")
                break
            fi
        done
    done

    num_pkgs=${#pkgs[@]}
    i=1
    echo
    for pkg in "${pkgs[@]}"
    do
        echo -en "\rScanning package $i/$num_pkgs"
        mod_id=${mod%% *}  # strip the version number off
        gofzdoc_filter "go doc -all $pkg" "$pkg" >> "$cache"
        ((i++))
    done
    echo
    echo "Index for go.mod built."
}

function gofzdoc_run() {
    type go >/dev/null 2>&1 || { echo >&2 "The go tool must be installed."; exit 1; }
    type fzf >/dev/null 2>&1 || { echo >&2 "fzf must be installed to use this."; exit 1; }

    m_version='^go version go(.+) '
    if [[ ! $(go version) =~ $m_version ]]; then
        echo 'Unable to get go version.'
        return 1
    fi
    go_version="${BASH_REMATCH[1]}"
    if [[ ! -r "${INDEX_DIR}/${go_version}.txt" ]]; then
        echo "No index found for go version $go_version."
        echo "Building index now. This may take a minute, but will only happen once per go version."
        gofzdoc_build_index "$go_version"
    fi
    mod_index=""
    if [[ -f go.mod ]]; then
        out=$(cksum go.mod)
        sum=${out%% *}
        mod_index=$sum
        if [[ ! -r "${INDEX_DIR}/${sum}.txt" ]]; then
            echo "No index found for go.mod"
            echo "Building index for go.mod now. This must be done every time go.mod changes."
            gofzdoc_build_mod_index
        fi
    fi

    if [[ -f go.mod ]]; then
        thing=$(cat "${INDEX_DIR}/${go_version}.txt" "${INDEX_DIR}/${mod_index}.txt" | fzf --preview "source ${SCRIPTPATH} && gofzdoc_preview {}")
    else
        thing=$(fzf --preview "source ${SCRIPTPATH} && gofzdoc_preview {}" < "${INDEX_DIR}/${go_version}.txt")
    fi
    go doc $(get_pkg_and_symbol "$thing")
}

function gofzdoc_preview() {
    go doc $(get_pkg_and_symbol "$1") \
        | if [[ "$GOFZDOC_ENABLE_PREVIEW_WRAP" == 1 ]]; then fmt -w $FZF_PREVIEW_COLUMNS; else cat; fi \
        | if [[ "$GOFZDOC_ENABLE_PREVIEW_BAT" == 1 ]]; then bat --wrap auto --terminal-width $COLUMNS --color always --plain --language go; else cat; fi
}

function gofzdoc-clear-cache() {
    rm ${INDEX_DIR}/*
}
