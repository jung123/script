#!/bin/expect -f

set timeout 30
set ADDR 172.17.0.
set USER test_user
set PASSWD "passwd\r"
set dclass [lindex $argv 0]

# docker repo server에 접속하기
spawn ssh $USER@$ADDR$dclass

# 최초 password 입력
expect "password: " {
	send $PASSWD
}
sleep 0.3
# root 계정으로 변경하기
expect "$ " {
	send "su\r"
}

sleep 0.3
expect "Password: " {
	send $PASSWD
}

interact


