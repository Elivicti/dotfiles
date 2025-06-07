#!/bin/bash

script=$(cd `dirname $0`; pwd)

if [ $# -lt 1 ] || { [ "$1" != "-e" ] && [ "$1" != "-d" ]; }; then
	echo "Usage: $0 [-e|-d] [password]"
	echo "  -e        Perform encryption"
	echo "  -d        Perform decryption"
	echo "  password: Optional. If omitted, read from stdin"
	exit 1
fi

mode="$1"
password=""
private_key="$script/.ssh/id_rsa"

if [ "$mode" == "-e" ] && [ ! -f "$private_key.pvt" ]; then
	echo "$private_key.pvt is not a file"
	exit 1
elif [ "$mode" == "-d" ] && [ ! -f "$private_key.enc" ]; then
	echo "$private_key.enc is not a file"
	exit 1
fi

if [ $# -ge 2 ]; then
	password="$2"
else
	read -rsp "Enter password: " password
	echo
fi


if [ "$mode" == "-e" ]; then
	output=$(openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
		-in  "$private_key.pvt" \
		-out "$private_key.enc" \
		-pass pass:"$password" 2>&1)
	result=$?

	if [ $result -ne 0 ]; then
		echo "Encryption failed: $output" >&2
		exit $result
	else
		chmod 644 "$private_key.enc"
		exit 0
	fi

else
	output=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
		-in  "$private_key.enc" \
		-out "$private_key"     \
		-pass pass:"$password" 2>&1)
	result=$?

	if [ $result -ne 0 ]; then
		echo "Decryption failed: $output" >&2
		exit $result
	else
		chmod 600 "$private_key"
		exit 0
	fi
fi

