#!/bin/bash

show_requirements() {
  echo 'getO365Endpoints-ng.sh is missing.`
  ' >&2
}

show_help() {
  echo "Generate IPs block to WL for a specific O365 service

Sample output :
  $0 LYO

  
Usage:

    $0 [-h] [-v] -c <optimize,allow,default> <product>

  Options:
    -c
      Category (optimize, default, allow) -- comma separated

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
verbose=0
categories=""

while getopts "h?vc:" opt; do
    case "$opt" in
    c)
        categories="$OPTARG"
        ;;
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

o365endpoints="$(which getO365Endpoints-ng.sh)"
[[ $o365endpoints == "" ]] && show_requirements && exit 1
[[ $categories == "" ]] && show_help && exit 1

components="$*"

[[ $components == "" ]] && show_help && exit 1

for component in $components; do
  
  echo "$component ALLOW"
  $o365endpoints -c $categories | grep -i $component | grep '/' | cut -d" " -f2,3 | sort | uniq
  echo ""
done

exit 0
