#!/bin/bash

show_requirements() {
  echo 'iconv or dos2unix is missing.
Please install it with `brew install iconv && brew install dos2unix`
' >&2
}

show_help() {
  echo "Parse HIPS logs to extract IP of blocked requests.
  
Usage:

    $0 [-v] [-h] <hips_log_file>

  Options:

    -v
      Verbose output.

    -h
      Show this help.
" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
log_file=""
verbose=0

while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

log_file="$1"
iconv="$(which iconv)"
dos2unix="$(which dos2unix)"

[[ $iconv == "" ]] && show_requirements && exit 1
[[ $dos2unix == "" ]] && show_requirements && exit 1
[[ ! -f "$log_file" ]] && show_help && exit 1

$iconv -c -f utf-16 -t ascii $log_file | dos2unix | grep -B 3 'Bloqu' | grep 'Adresse IP/utilisateur' | cut -d':' -f2- | grep -v ':' | sort | uniq | cut -d" " -f2 
