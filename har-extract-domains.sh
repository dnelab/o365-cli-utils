#!/bin/bash

show_help() {
  echo "Extract all fetched URL from har archive (sorted and de-duplicate).
  
Usage:

    $0 <harchive.har>

Examples:

    $0 mybrowser-archive.har

" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?vp:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

har="$1"

[[ $har == "" ]] && show_help && exit 1

grep '"url"' $1 | cut -d'"' -f4 | cut -d'/' -f3 | sort | uniq
