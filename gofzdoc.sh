#!/bin/bash
set -euo pipefail

GOFZDOC_LIB_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P)/gofzdoc-lib.sh"
GOFZDOC_VERSION=0.0.0

if [[ $# -ge 1 && ("$1" == "--help" || "$1" == "-h") ]]; then
    fmt <<EOF
Usage: gofzdoc [-h | --help] [-v | --version]

Environment variables:
    GOFZDOC_ENABLE_PREVIEW_WRAP
        Set to "1" to enable line wrapping in the preview window. This doesn't work well for some docs so it's disabled by default.
    GOFZDOC_ENABLE_PREVIEW_BAT
        Enable syntax highlighting using bat (https://github.com/sharkdp/bat).
    GOFZDOC_OPEN_BROWSER_URL
        Which base URL to open with Ctrl-x. Default is https://godoc.org/

Other commands:
    gofzdoc-clear-cache - clear the index cache
EOF
    exit 0
fi

if [[ $# -ge 1 && ("$1" == "--version") || "$1" == "-v" ]]; then
    echo "gofzdoc $GOFZDOC_VERSION"
    exit 0
fi

source "$GOFZDOC_LIB_PATH"
__gofzdoc_run
