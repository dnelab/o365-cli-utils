#!/usr/local/bin/bash

show_requirements() {
  echo '' >&2
}

show_help() {
  echo "Shortened a password list to keep 1000 word of 4 chars length min according to AAD password protection rules.
  
Usage:

    $0 [-v] [-h] <ip>

  Options:

    -v
      Verbose output.

    -h
      Show this help.

Examples:

    $0 password-list-file.txt

" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ip=""
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

file="$*"


[[ $file == "" ]] && show_help && exit 1

## sort by line numbers
cat $file | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | awk 'length($0)>3' | head -n 1000
