#!/usr/local/bin/bash
sp="/-\|"
sc=0
tput civis
spin() {
	printf "\b${sp:sc++:1}"
	[ $sc -gt ${#sp} ] && sc=0
}
endspin() {
	tput cnorm
	printf "\r%s\n" "$@"
}
spinresult() {
	printf "\b"
}

trap 'endspin;exit 1;' SIGINT 
trap 'endspin;exit 1;' SIGTERM

