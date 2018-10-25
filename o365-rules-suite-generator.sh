#!/bin/bash

show_requirements() {
  echo 'wget or jq is missing.
Please install it with `brew install jq`
Please install it with `brew install wget`
  ' >&2
}

show_help() {
  echo "Forge all network requirements (in /tmp by default) :

  - Proxy
  - DNS resolution
  - Firewall local and perimeter 
  
Usage:

    $0 [-v] [-h] endpoints-file

  Options:
  
    -v
      Verbose output (add traversal zones).

    -h
      Show this help.

Examples:
    
    $ $0 o365-endpoints-20180501
      
" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
verbose=0

while getopts "h?vp:" opt; do
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
dest_dir="/tmp"

[[ $file == "" ]] && show_help && exit 1

today=$(date +%Y%m%d)
out_file=$dest_dir/$today

cat $file | cut -d " " -f 2 | sort > $out_file-local-fw
cat $file | cut -d " " -f 2,3 | sort > $out_file-ext-fw
./oo365-pac-forge-ng.sh -c $cat $products > $out_file-pac
