#!/bin/bash

show_help() {
  echo "Determine if an URL is accessible through a given proxy without providing authentification credentials.
  
Usage:

    $0 [-v] [-h] [-p http://proxy] <fqdn>

  Options:

    -p proxy
      Proxy full FQDN to use

    -v
      Verbose output.

    -h
      Show this help.

Examples:

    $0 -p http://proxy.acme.com:8080 http://www.google.fr
    $0 -p http://proxy.acme.com:8080 http://www.google.fr https://www.yahoo.fr

" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ip=""
verbose=0
proxy=""

while getopts "h?vp:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    p)  proxy="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

fqdns="$*"
flags="-f -s" # fail silent

[[ $proxy == "" ]] && show_help && exit 1
[[ $verbose == 0 ]] && flags="--silent"

for fqdn in $fqdns; do

  ## check if we are dealing with http or https FQDN
  S=${fqdn:4:1}

  write_out=""
  if [[ "$S" = "s" ]]; then
    write_out="http_connect"
  else 
    write_out="http_code"
  fi

  http_code=`curl --proxy "$proxy" -o /dev/null $flags -L -X GET --head --write-out "%{$write_out}" "$fqdn"`
  curl_ret=$?
  ok="OK"

  [[ $http_code -eq "000" ]] && ok="KO (curl return code $curl_ret)";

  [[ $http_code == 407 ]] && ok="KO";
  echo "$fqdn : $http_code - $ok"
  
#  if [[ $http_code == 407 ]]; then
 # fi
done
