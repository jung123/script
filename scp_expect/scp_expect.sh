#!/bin/bash
#!/usr/bin/expect
#set -x
#set -e

# Remote Info 
REMOTE_ADDR_BASE="172.17.0."
REMOTE_USER="test_user"
REMOTE_PASSWD="passwd"
REMOTE_BASE_DIR="/home/test_user/"

REMOTE_ADDR_BASE_CONFIG_NAME=REMOTE_ADDR_BASE
REMOTE_USER_CONFIG_NAME=REMOTE_USER
REMOTE_PASSWD_CONFIG_NAME=REMOTE_PASSWD
REMOTE_BASE_DIR_CONFIG_NAME=REMOTE_BASE_DIR

# Command
CAT=`which cat`
EXPECT=`which expect`
GREP=`which grep`
CUT=`which cut`
HEAD=`which head`
SED=`which sed`
TOUCH=`which touch`
RM=`which rm`
MV=`which mv`
CHMOD=`which chmod`
AWK=`which awk`
SCP=`which scp`

usage() {
	echo "----------- Usage ----------"
	echo "-- File Trasforming Mode"
	echo "#> $0 [Local Loc] [Dst Loc] : Send Local Location file To Dst Loc"
	echo "#> $0 -R [Local Loc] [Dst Loc] : Get Dst Location File to Local Location"
	echo "-- Modify Remote Config Mode"
	echo "#> $0 -dconf"
	echo "----------------------------"
}

print_conf() {
	echo "[REMOTE_ADDR_BASE]:$REMOTE_ADDR_BASE"
	echo "[REMOTE_USER]:$REMOTE_USER"
	echo "[REMOTE_PASSWD]:$REMOTE_PASSWD"
	echo "[REMOTE_BASE_DIR]:$REMOTE_BASE_DIR"
}

set_config() {
	local config_name
	local config_line
	local arg_config
	local arg_tmp_file
	local arg_file
	local prev_conf
	local regex='^[0-9]+$'

	if [ $# -ne 5 ]; then
		echo "Invalid Arg Num"
		return -1
	fi

	config_name=$1
	config_line=$2
	arg_config=$3
	arg_file=$4
	arg_tmp_file=$5

	#check line num type
	if ! [[ $config_line =~ $regex ]]; then
		echo "$config_line value type is not integer"
		return -1
	fi

	# Get Prev Config
	prev_conf=`$SED -n ''$config_line','$config_line' p' $arg_file`
	if [ $? -ne 0 ]; then
		echo "[Fail]: SED Get Prev Conf"
		return -1
	fi

	# Set Config Value in File
	$SED ''$config_line','$config_line' s+'$prev_conf'+'$config_name'="'$arg_config'"+g' $arg_file > $arg_tmp_file
	if [ $? -ne 0 ]; then
		echo "[Fail]: SED Set Config Valie in File"
		return -1
	fi

	return 0
}

check_remote_addr() {
	# X.X.X
	local regex="^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
	local address
	local convert_address

	if [ $# -ne 1 ]; then
		echo "Invalid Arg num"
		return -1;
	fi
	address=$1

	# Check Address
	if ! [[ $address =~ $regex ]]; then
		echo "Invalid IP Address : $address"
		return -1;
	fi

	return 0;
}

change_config() {
	local arg_remote_addr
	local arg_user
	local arg_passwd
	local arg_base_dir
	local line_num
	local tmp_file_1
	local tmp_file_2

	if [ $# -ne 1 ]; then
		echo "Invalid Arg Num"
		return -1
	fi

	if [ $1 != "-dconf" ]; then
		echo "Invalid Arg"
		return -1
	fi

	# Print Curr Conf
	echo "Curr conf is ..."
	print_conf
	echo "..."

	read -p "Remote Address [ A.B.C] : " arg_remote_addr
	read -p "Remote User : " arg_user
	read -p "Remote User Passwd : " arg_passwd
	read -p "Remote Base Dir: " arg_base_dir

	# create tmp file	
	tmp_file_1=$0.tmp_1
	tmp_file_2=$0.tmp_2
	$CAT $0 > $tmp_file_1

	# Check Remote Address
	check_remote_addr $arg_remote_addr
	if [ $? -ne 0 ]; then
		return -1
	fi
	arg_remote_addr=`echo "$arg_remote_addr."`

	# Set Remote Addr
	line_num=`$CAT $0 | grep -n $REMOTE_ADDR_BASE_CONFIG_NAME | $CUT -d ":" -f 1 | $HEAD -n 1`
	set_config $REMOTE_ADDR_BASE_CONFIG_NAME $line_num $arg_remote_addr $tmp_file_1 $tmp_file_2
	if [ $? -ne 0 ]; then
		return -1
	fi
	REMOTE_ADDR=$arg_remote_addr
	$CAT $tmp_file_2 > $tmp_file_1

	# Set Remote User
	line_num=`$CAT $0 | grep -n $REMOTE_USER_CONFIG_NAME | $CUT -d ":" -f 1 | $HEAD -n 1`
	set_config $REMOTE_USER_CONFIG_NAME $line_num $arg_user $tmp_file_1 $tmp_file_2
	if [ $? -ne 0 ]; then
		return -1
	fi
	REMOTE_USER=$arg_user
	$CAT $tmp_file_2 > $tmp_file_1

	# Set Remote Base Dir
	line_num=`$CAT $0 | grep -n $REMOTE_BASE_DIR_CONFIG_NAME | $CUT -d ":" -f 1 | $HEAD -n 1`
	set_config $REMOTE_BASE_DIR_CONFIG_NAME $line_num $arg_base_dir $tmp_file_1 $tmp_file_2
	if [ $? -ne 0 ]; then
		return -1
	fi
	REMOTE_BASE_DIR=$arg_base_dir
	$CAT $tmp_file_2 > $tmp_file_1

	# Set Remote Password
	line_num=`$CAT $0 | grep -n $REMOTE_PASSWD_CONFIG_NAME | $CUT -d ":" -f 1 | $HEAD -n 1`
	set_config $REMOTE_PASSWD_CONFIG_NAME $line_num $arg_passwd $tmp_file_1 $tmp_file_2
	if [ $? -ne 0 ]; then
		return -1
	fi
	REMOTE_PASSWD=$arg_passwd
	$CAT $tmp_file_2 > $tmp_file_1

	$MV $tmp_file_1 $0
	$RM $tmp_file_2
	$CHMOD 755 $0

	return 0
}

expect_command() {
	if [ $# -ne 2 ]; then
		echo "Invalid Arg num"
		return -1
	fi

	local command=`echo "$1 $2"`
	echo "[Command]: $command"
	echo $REMOTE_PASSWD

	$EXPECT <<- EOF 
		set timeout 30
		spawn $SCP $command
		sleep 0.5

		expect {
			"password:*" {
				send "$REMOTE_PASSWD\r"
			}
			"(yes/no)?*" {
				send "yes\r"
				exp_continue
			}
		}

		interact

		expect eof
	EOF

	if [ $? -ne 0 ]; then
		echo "Fail: Expect..."
		return -1;
	fi

	return 0;
}

send_file() {
	local local_loc
	local dst_loc
	local remote_addr_tmp

	if [ $1 == "-R" ]; then
		remote_addr_tmp=$REMOTE_ADDR_BASE$2
		local_loc=$3
		dst_loc=$4
	else
		remote_addr_tmp=$REMOTE_ADDR_BASE$1
		local_loc=$2
		dst_loc=$3
	fi

	# Send File or Get File
	if [ $1 == "-R" ]; then
		expect_command $REMOTE_USER@$remote_addr_tmp:$REMOTE_BASE_DIR$dst_loc $local_loc
	else
		expect_command $local_loc $REMOTE_USER@$remote_addr_tmp:$REMOTE_BASE_DIR$dst_loc
	fi
	if [ $? -ne 0 ]; then
		return -1;
	fi

	return 0;
}

main() {
	# Print Curr config
	if [ $# -eq 1  ] && [ $1 == '-print' ]; then
		print_conf
		return 0
	fi

	# Chang Remote Config
	if [ $# -eq 1 ]; then
		change_config $1
		if [ $? -ne 0 ]; then
			return -1
		fi
		return 0
	fi

	# File Transforming Mode
	local remote_addr_tmp=$REMOTE_ADDR_BASE$1
	if [ $1 == "-R" ] && [ $# -eq 4 ]; then
		send_file $1 $2 $3 $4
		if [ $? -ne 0 ]; then
			return -1
		fi
		return 0
	fi

	if [ $# -eq 3 ]; then
		send_file $1 $2 $3
		if [ $? -ne 0 ]; then
			return -1
		fi
		return 0
	fi

	return -1;
}

main $1 $2 $3 $4
if [ $? -ne 0 ]; then
	usage
fi
