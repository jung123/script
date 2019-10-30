#!/bin/bash
#set -f
#set -o noglob
#shopt -op noglob

XARGS=`which xargs`

list=("eth2" "eth3" "eth0" "eth1" "eth4" "eth7" "eth5" "eth6" )
declare -a sorted_list

function test_func()
{
	local index
	local list_len=${#list[@]}

	echo "length : $list_len"
	echo "${list[@]}"
	((index=0))

	echo "#1 "
	IFS=$'\n'
	sorted_list=($(sort <<< "${list[*]}"));
	unset IFS
	echo ${sorted_list[@]}
}

test_func
