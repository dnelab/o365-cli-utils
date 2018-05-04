#!/bin/bash

show_requirements() {
  echo 'getO365Endpoints-ng.sh is missing.`
  ' >&2
}

show_help() {
  echo "Generate pac proxy DIRECT block for a specific O365 service

Sample output :
  $0 LYO

  if( dnsDomainIs(host, 'lync.com') ||
      dnsDomainIs(host, 'skype.com')
  ) {
    return 'DIRECT';
  }
  
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
  
  domains=$($o365endpoints -c $categories | grep $component | grep -v '/' | cut -d" " -f2 | sort | uniq )

  echo "// throw O365 $component traffic through FW directly"
  echo "if("
  firstLoop=""
  olddomain=""
  for domain in $domains; do

    resolvable=$(dns-resolution-check.sh "$domain" | grep "OK")
    if [[ $? == 1 ]]; then
      echo "// not resolvable : $domain"
      continue
    fi    

    echo "    $firstLoop shExpMatch(host, \"$domain\")" 
    olddomain=$ldomain
  
    firstLoop=" ||"
  done

  echo ") {  return 'DIRECT'; }"
  
done

exit 0
