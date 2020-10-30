#!/usr/bin/env bash
#
# Blob storage expander
#   prepare_final.sh
# Author: jtFuruhata
# Copyright (c) 2020 ETロボコン実行委員会, Released under the MIT license
# See LICENSE
#

datumDir="$1"
cd "$datumDir"
while read line; do
    teamId=`echo $line | awk '{print $1}'`
    combinedId=`echo $line | awk '{print $2}'`
    if [ -d $teamId ]; then
        mv $teamId $combinedId
    fi
done < "$ETROBO_ROOT/dist/teamlist.txt"

while read line; do
    combinedId=`echo "$line" | awk '{print $1}'`
    prefixies=`echo "$line" | awk '{print $2}'`
    requestId=`echo "$line" | awk '{print $3}'`
    course=${prefixies:0:2}
    cd "$combinedId"

    if [ ! -d l_race ] || [ ! -d r_race ]; then
        echo "$line"
        srcDir="$requestId/req"
        srcName="`ls -1 $requestId/req 2>&1 | head -n 1`"
        distName="${prefixies}${requestId}.zip"
        cp "$srcDir/$srcName" "$distName" > /dev/null 2>&1
        if [ "$?" != "0" ]; then
            echo "cp error"
            exit 1
        else
            unzip "$distName" > /dev/null 2>&1
            if [ "$?" != "0" ]; then
                echo "unzip error"
                exit 1
            else
                if [ ! -f "__race/${course}__race.asp" ]; then
                    echo "$combinedId ${course}__race.asp not found"
                    exit 1
                else
                    mv "__race" "${course}race"
                fi
            fi
        fi
    fi
    cd "$datumDir"
done < "$ETROBO_ROOT/dist/requests.txt"

