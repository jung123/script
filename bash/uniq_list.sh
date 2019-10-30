#!/bin/bash
#set -x
#set -e

# UTIL
AWK=`which awk`
UNIQ=`which uniq`
TR=`which tr`

list=("i40e" "igb" "i40e" "igb" "eth1" "eth0" "eth2" "eth1" "eth2" "eth4" "eth3")

function make_uniq_list()
{
    local uniqued_list=()
    # print
    echo "list : ${list[@]}"

    # method 1
    # 해당 방법은 파일의 행별로 처리할 때 의미가 있는 것 같다.
    uniqued_list=()
    uniqued_list=($(echo ${list[@]} | tr ' ' '\n' | ${UNIQ} ))
    echo "method 1: ${uniqued_list[@]}"

    # method 2
    uniqued_list=()
    uniqued_list=($(echo ${list[@]} | tr ' ' '\n' | ${AWK} '!x[$0]++ {print $0}'))
    echo "method 2: ${uniqued_list[@]}"

    # method 3
    uniqued_list=()
    uniqued_list=($(echo ${list[@]} | tr ' ' '\n' | sort -u | tr '\n' ' '))
    echo "method 3: ${uniqued_list[@]}"

    return 0
}

make_uniq_list
