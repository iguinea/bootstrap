#!/bin/bash

while true
do
    ping -c 1 8.8.8.8 > /dev/null
    ret=$?

    if [[ ! $ret == 0 ]]
    then
        
        break
    fi
    sleep 5
    echo -n  "."
done
echo
echo "Date"
date