#!/usr/bin/env bash
#
# Blob storage expander
#   prepare_final.sh
# Author: jtFuruhata
# Copyright (c) 2020 ETロボコン実行委員会, Released under the MIT license
# See LICENSE
#

# expand </path/to/datum>
if [ "$1" == "expand" ]; then
    datumDir="$2"
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

# spread </path/to/Results>
elif [ "$1" == "spread" ]; then
    results="$2"
    cd "$results"
    dist="`dirname $(pwd)`/up_`basename $(pwd)`"
    rm -rf "$dist"
    mkdir -p "$dist"
    for line in `ls -1`; do
        echo $line
        requestID="`echo $line | sed -E 's/._._(.*)\.zip/\1/'`"
        teamID="`cat \"$ETROBO_ROOT/dist/requests.txt\" | grep $requestID | awk '{print $1}'`"
        course="`cat \"$ETROBO_ROOT/dist/requests.txt\" | grep $requestID | awk '{print $2}' | sed -E 's/^(.)_._/\U\1/'`"
        folderName="${teamID}_${course}"
        innerName="`unzip -l $line | sed '1,3d' | head -n 1 | awk '{print $4}' | sed -E 's/^(.*)\/$/\1/'`"
        cp "$line" "$dist/"
        cd "$dist"
        unzip -o "$line" > /dev/null
        mv "$innerName" "$folderName"
        rm "$line"
        cd "$results"
    done

# changeFps </path/to/up_sim> [reencode <divider>] <fps>
elif [ "$1" == "changeFps" ]; then
    src="$2"
    unset reencode
    if [ "$3" == "reencode" ]; then
        reencode="reencode"
        divider="$4"
        shift 2
    fi
    fps="$3"
    if [ -z "$fps" ]; then
        fps="60"
    fi
    cd "$src"
    for line in `ls -1 "$src"`; do
        echo $line
        folderName="$line"
        cd "$folderName"
        target="`ls -1 | grep \"^[LR][0-9]\\{8\\}-.*.mp4$\" | head -n 1`"
        if [ -z "$reencode" ]; then
            ffmpeg -y -i $target -c copy -f h264 $target.h264 -loglevel 8
            ffmpeg -y -r $fps -i $target.h264 -c copy $target -loglevel 8
            rm $target.h264
        else
            ffmpeg -y -i $target -vf "setpts=${divider}*PTS" -r $fps $target.reencode.mp4
            rm $target
            mv $target.reencode.mp4 $target
        fi
        cd "$src"
    done

# updateResult </path/to/up_sim>
elif [ "$1" == "updateResult" ]; then
    src="$2"
    cd "$src"
    good=0
    bad=0
    for target in `ls -1 "$src"`; do
#    line="E179_L"
        if [ -d "$src/$target" ]; then
            teamID=${target:0:4}
            course=${target:5:1}
            if [ "$course" == "L" ]; then
                select="left"
            else
                select="right"
            fi
            cd "$src/$target"
            csv="`ls -1 *.csv`"
            jsonTime="`cat result.json | jq -r .${select}Measurement.TIME`"
            line=1
            csvTime="`cat $csv | tail -n 1 | awk -F ',' '{print $4}'`"
            while [ "$jsonTime" -lt "$csvTime" ]; do
                    line=$(( $line + 1 ))
                    csvTime="`cat $csv | tail -n $line | head -n 1 | awk -F ',' '{print $4}'`"
            done
            if [ "$line" == "1" ]; then
                good=$(( $good + 1 ))
                echo "$target: $jsonTime -> $csvTime"
            else
                bad=$(( $bad + 1 ))
                #echo "$target drifted $line frame"
            fi
        fi
    done
    echo "good: $good  bad: $bad"

# getCsv </path/to/up_sim>
elif [ "$1" == "getCsv" ]; then
    src="$2"
    cd "$src"
    rm -rf ../csv
    mkdir ../csv
    count=0
    for target in `ls -1 "$src"`; do
        if [ -d "$src/$target" ]; then
            teamID=${target:0:4}
            course=${target:5:1}
            cd "$src/$target"
            csv="`ls -1 *.csv`"
            echo "$csv -> ../../csv/$target.csv"
            cp $csv ../../csv/$target.csv
            count=$(( $count + 1 ))
        fi
    done
    echo "count: $count"

# updateMatchmaker </path/to/up_sim> </path/to/update>
elif [ "$1" == "updateMatchmaker" ]; then
    upsim="$2"
    update="$3"
    cd "$upsim"
    for target in `ls -1 "$update"`; do
        teamID=${target:2:4}
        course=${target:0:1}
        echo "${teamID}_${course} <- $target"
        cp "$update/$target" "${teamID}_${course}"
    done
else
    echo "usage:"
    echo "  prepare_final.sh expand </path/to/Datum>"
    echo "  prepare_final.sh spread </path/to/Results>"
    echo "  prepare_final.sh changeFps </path/to/up_sim> [reencode <divider>] <fps>"
    echo "  prepare_final.sh updateResult </path/to/up_sim>"
    echo "  prepare_final.sh getCsv </path/to/up_sim>"
fi
