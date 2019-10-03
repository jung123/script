#!/bin/bash
#set -x
#set -e

JQ=`which jq`

echo "{\"foo\":\"bar\"}" | $JQ "."
