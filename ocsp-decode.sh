#!/bin/bash

show_help() {
  echo "Decode an OCSP payload.
  
Usage:

    $0 [-h] [-v] <ocsp_payload>

  Options:

    -v
      Verbose mode

    -h
      Show this help.

Examples:

    For this kind of request : http://ocsp.verisign.com/ocsp/status/MFEwTzBNMEswSTAJBgUrDgMCGgUABBR8rDZ7XHVM4v9dleAl%2FfaHn9a%2FoQQUwfBYxzpw4VJn375XfmInyHRSJicCEAh6bVxvYpNPusT9Q%2BEUGJ0%3D
    You should decode it like this :

    $0 MFEwTzBNMEswSTAJBgUrDgMCGgUABBR8rDZ7XHVM4v9dleAl%2FfaHn9a%2FoQQUwfBYxzpw4VJn375XfmInyHRSJicCEAh6bVxvYpNPusT9Q%2BEUGJ0%3D

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
    v)
        verbose=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

payload="$*"

[[ $payload == "" ]] && show_help && exit 1


## bash only dep @see https://stackoverflow.com/questions/6250698/how-to-decode-url-encoded-string-in-shell
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

[[ $verbose == 1 ]] && echo "Payload raw: $payload"

## urldecode payload
payload_decoded=$(urldecode $payload)


[[ $verbose == 1 ]] && echo "Payload decoded: $payload_decoded"


echo $payload_decoded | base64 -D | openssl asn1parse -i -inform der