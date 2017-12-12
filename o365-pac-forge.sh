#!/bin/bash

show_requirements() {
  echo 'getO365Endpoints.sh is missing.
Please install it with `brew install `
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

    $0 [-h] [-v] <product>

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

o365endpoints="$(which getO365Endpoints.sh)"
[[ $o365endpoints == "" ]] && show_requirements && exit 1

components="$*"

[[ $components == "" ]] && show_help && exit 1

for component in $components; do
  
  domains=$($o365endpoints | grep "$component" | grep -v '/' | cut -d" " -f2 | sed -e s/\*.// )

  echo "// throw O365 $component traffic through FW directly"
  echo "if("
  firstLoop=""
  for domain in $domains; do
  
    echo "    $firstLoop dnsDomainIs(host, \"$domain\")" 
    firstLoop=" ||"
  done

  echo ") {  return 'DIRECT'; }"
  
done

exit 0
