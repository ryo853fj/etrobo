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
# if your video was fast-forwarded at 2x speed, use `reencode 2.0 60`
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
    count=0
    for target in `ls -1 "$src"`; do
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
            record="`cat $csv | tail -n 1 | sed -E 's/\r//g'`"
            csvTime="`echo "$record" | awk -F ',' '{print $1}'`"
            csvCounter="`echo "$record" | awk -F ',' '{print $2}'`"
            csvFilename="`echo "$record" | awk -F ',' '{print $3}'`"
            csvTIME="`echo "$record" | awk -F ',' '{print $4}'`"
            csvMEASUREMENT_TIME="`echo "$record" | awk -F ',' '{print $5}'`"
            csvRUN_TIME="`echo "$record" | awk -F ',' '{print $6}'`"
            csvGATE1="`echo "$record" | awk -F ',' '{print $7}'`"
            csvGATE2="`echo "$record" | awk -F ',' '{print $8}'`"
            csvGOAL="`echo "$record" | awk -F ',' '{print $9}'`"
            csvGARAGE_STOP="`echo "$record" | awk -F ',' '{print $10}'`"
            csvGARAGE_TIME="`echo "$record" | awk -F ',' '{print $11}'`"
            csvSLALOM="`echo "$record" | awk -F ',' '{print $12}'`"
            csvPETBOTTLE="`echo "$record" | awk -F ',' '{print $13}'`"
            csvBLOCK_IN_GARAGE="`echo "$record" | awk -F ',' '{print $14}'`"
            csvBLOCK_YUKOIDO="`echo "$record" | awk -F ',' '{print $15}'`"
            csvCARD_NUMBER_CIRCLE="`echo "$record" | awk -F ',' '{print $16}'`"
            csvBLOCK_NUMBER_CIRCLE="`echo "$record" | awk -F ',' '{print $17}'`"
            csvBLOCK_BINGO="`echo "$record" | awk -F ',' '{print $18}'`"
            csvENTRY_BONUS="`echo "$record" | awk -F ',' '{print $19}'`"

            json="`cat result.json`"
            json="`echo \"$json\" | jq \".${select}Measurement.TIME|=\\\"$csvTIME\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.MEASUREMENT_TIME|=\\\"$csvMEASUREMENT_TIME\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.RUN_TIME|=\\\"$csvRUN_TIME\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.GATE1|=\\\"$csvGATE1\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.GATE2|=\\\"$csvGATE2\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.GOAL|=\\\"$csvGOAL\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.GARAGE_STOP|=\\\"$csvGARAGE_STOP\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.GARAGE_TIME|=\\\"$csvGARAGE_TIME\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.SLALOM|=\\\"$csvSLALOM\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.PETBOTTLE|=\\\"$csvPETBOTTLE\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.BLOCK_IN_GARAGE|=\\\"$csvBLOCK_IN_GARAGE\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.BLOCK_YUKOIDO|=\\\"$csvBLOCK_YUKOIDO\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.CARD_NUMBER_CIRCLE|=\\\"$csvCARD_NUMBER_CIRCLE\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.BLOCK_NUMBER_CIRCLE|=\\\"$csvBLOCK_NUMBER_CIRCLE\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.BLOCK_BINGO|=\\\"$csvBLOCK_BINGO\\\"\"`"
            json="`echo \"$json\" | jq \".${select}Measurement.ENTRY_BONUS|=\\\"$csvENTRY_BONUS\\\"\"`"

            echo $json | jq -M . > result.json
            count=$(( $count + 1 ))
        fi
    done
    echo "count: $count"

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
        if [ -d "${teamID}_${course}" ]; then
            cp "$update/$target" "${teamID}_${course}/"
        fi
    done

# copyMp4 </path/to/up_sim_dist> </path/to/up_sim_src> 
elif [ "$1" == "copyMp4" ]; then
    dist="$2"
    src="$3"
    cd "$src"
    for line in `ls -1 "$src"`; do
        echo $line
        folderName="$line"
        cd "$folderName"
        target="`ls -1 | grep \"^[LR][0-9]\\{8\\}-.*.mp4$\" | head -n 1`"
        cp "$target" "$dist/$folderName"
        cd "$src"
    done

# copyCsv </path/to/up_sim_dist> </path/to/up_sim_src> 
elif [ "$1" == "copyCsv" ]; then
    dist="$2"
    src="$3"
    cd "$src"
    for line in `ls -1 "$src"`; do
        echo $line
        folderName="`echo \"$line\" | sed -E 's/^(.*)\.csv$/\1/'`"
        cd "$dist/$folderName"
        target="`ls -1 | grep \"^[LR][0-9]\\{8\\}-.*.csv$\" | head -n 1`"
        cp "$src/$line" "./$target"
        cd "$src"
    done

# touchThemAll </path/to/folder> [<"YYYY-MM-DD HH:MM:SS">]
elif [ "$1" == "touchThemAll" ]; then
    folderName="$2"
    datetime="$3"
    for target in `find "$folderName"`; do
        if [ -z "$datetime" ]; then
            echo "$target"
            touch "$target"
        else
            echo "$target -> $datetime"
            touch -cm -d "$datetime" "$target"
        fi
    done

# devideCS </path/to/result>
elif [ "$1" == "devideCS" ]; then
    src="$2"
    dist="${src}_cs"
    if [ ! -d "$dist" ]; then
        mkdir "$dist"
        while read line; do
            echo $line
            if [ -d "${src}/${line}_L" ]; then
                echo "${src}/${line}_L -> $dist"
                mv "${src}/${line}_L" "$dist/"
            fi
            if [ -d "${src}/${line}_R" ]; then
                echo "${src}/${line}_R -> $dist"
                mv "${src}/${line}_R" "$dist/"
            fi
        done < "$ETROBO_ROOT/dist/teamlist_cs.txt"
    fi

# rezip </path/to/result>
elif [ "$1" == "rezip" ]; then
    src="$2"
    dist="${src}_zip"
    if [ ! -d "$dist" ]; then
        mkdir "$dist"
    fi
    cd "$src"
    for line in `ls -1 "$src"`; do
        echo $line
        zip -r "$dist/${line}.zip" $line
    done 

# renameResults </path/to/Results>
elif [ "$1" == "renameResults" ]; then
    src="$2"
    while read line; do
        raceID="`echo "$line" | awk '{print $1}'`"
        teamID="${raceID:0:4}"
        requestID="`echo "$line" | awk '{print $2}'`"
        target="${raceID:0:1}_${requestID}.zip"
        if [ -n "`cat \"$ETROBO_ROOT/dist/teamlist_cs.txt\" | grep $teamID`" ]; then
            echo "$raceID is a Championship team."
        elif [ -f "$src/${raceID}.zip" ]; then
            echo "$raceID -> $target"
            mv "$src/${raceID}.zip" "$src/$target"
        else
            echo "******** FATAL ERROR ******** $raceID not found."
        fi
    done < "$ETROBO_ROOT/dist/requests_org.txt"

# checkInit </path/to/Datum>
elif [ "$1" == "checkInit" ]; then
    folderName="$2"
    for target in `find "$folderName" | grep _race/settings.json$`; do
        raceName="`echo $(basename $(dirname $target)) | awk '{print toupper($1)}'`"
        race="${raceName:0:1}"
        teamID=$(basename $(dirname $(dirname $target)))
        combinedID="${teamID}_$race"
        if [ "$race" == "L" ]; then
            initX_default="3"
            initY_default="0"
            initZ_default="-15.61"
            initROT_default="90"
            initX="`cat \"$target\" | jq -r .initLX`"
            initY="`cat \"$target\" | jq -r .initLY`"
            initZ="`cat \"$target\" | jq -r .initLZ`"
            initROT="`cat \"$target\" | jq -r .initLROT`"
        else
            initX_default="-3"
            initY_default="0"
            initZ_default="-15.61"
            initROT_default="-90"
            initX="`cat \"$target\" | jq -r .initRX`"
            initY="`cat \"$target\" | jq -r .initRY`"
            initZ="`cat \"$target\" | jq -r .initRZ`"
            initROT="`cat \"$target\" | jq -r .initRROT`"
        fi
        if [ "$initX" != "$initX_default" ] || [ "$initY" != "$initY_default" ] || [ "$initZ" != "$initZ_default" ] || [ "$initROT" != "$initROT_default" ]; then
            echo "$combinedID, $initX, $initY, $initZ, $initROT"
        fi
    done

# getMovie </path/to/result> </path/to/result_rerun> [rev]
elif [ "$1" == "getMovie" ]; then
    result="$2"
    result_rerun="$3"
    rev="$4"
    if [ -z "$rev" ]; then
        dist="${result}_movie"
        selector="L"
        zPost="B"
    else
        dist="${result}_movie_rev"
        selector="R"
        zPost="R"
    fi
    if [ ! -d "$dist" ]; then
        mkdir "$dist"
    fi
    while read line; do
        teamID="`echo $line | awk '{print $1}'`"
        selectL="`echo $line | awk '{print $2}'`"
        selectR="`echo $line | awk '{print $3}'`"
        selectBest="`echo $line | awk '{print $4}'`"
        order="0`echo $line | awk '{print $5}'`"
        class="${teamID:0:1}"
        teamNo="${teamID:1:3}"
        prefix="${class}-${order:${#order}-2}${zPost}_${teamNo}_"
        if [ "$selectL" == "前" ]; then
            folderL="$result/${teamID}_L"
        else
            folderL="$result_rerun/${teamID}_L"
        fi
        if [ "$selectR" == "前" ]; then
            folderR="$result/${teamID}_R"
        else
            folderR="$result_rerun/${teamID}_R"
        fi
        if [ "${selectBest:0:1}" == "$selector" ]; then
            raceID="${teamID}_L"
            folderBest="$folderL"
        else
            raceID="${teamID}_R"
            folderBest="$folderR"
        fi
        
        for target in `ls -1 "$folderBest"/*.mp4`; do
            if [ -n "`echo $target | grep 計測動画`" ]; then
                cp "$target" "$dist/${prefix}mm.mp4"
                echo "${prefix}mm.mp4"
            else
                cp "$target" "$dist/${prefix}race.mp4"
                echo "${prefix}race.mp4"
            fi
        done
    done < "$ETROBO_ROOT/dist/cs_order.txt"

# renamePng </path/to/result>
elif [ "$1" == "renamePng" ]; then
    result="$2"
    while read line; do
        teamID="`echo $line | awk '{print $1}'`"
        selectL="`echo $line | awk '{print $2}'`"
        selectR="`echo $line | awk '{print $3}'`"
        selectBest="`echo $line | awk '{print $4}'`"
        order="0`echo $line | awk '{print $5}'`"
        class="${teamID:0:1}"
        teamNo="${teamID:1:3}"
        prefix="${class}-${order:${#order}-2}B_${teamNo}_"
        
        src="$result/${teamID}_リザルト.png"
        if [ -f "$src" ]; then
            echo "$src -> ${prefix}リザルト.png"
            mv "$src" "$result/${prefix}リザルト.png"
        else
            echo "error $src"
        fi
    done < "$ETROBO_ROOT/dist/cs_order.txt"

# divideMovie </path/to/movie> </path/to/output> best|rev [stretch <stretch frame>]
elif [ "$1" == "divideMovie" ]; then
    unset rev
    selector="B"
    if [ "$4" == "rev" ]; then
        rev="_rev"
        selector="R"
    fi
    unset stretch
    if [ "$5" == "stretch" ]; then
        stretch="$6"
    fi

    movie="$2$rev"
    dist="$3$rev"

    cd "$movie"
    IFS_back="$IFS"
    IFS=$'\n'
    for line in `cat "$ETROBO_ROOT/dist/cs_order.txt"`; do
        teamID="`echo $line | awk '{print $1}'`"
        selectL="`echo $line | awk '{print $2}'`"
        selectR="`echo $line | awk '{print $3}'`"
        selectBest="`echo $line | awk '{print $4}'`"
        order="0`echo $line | awk '{print $5}'`"
        class="${teamID:0:1}"
        teamNo="${teamID:1:3}"
        prefix="${class}-${order:${#order}-2}${selector}_${teamNo}_"
        
        src="${prefix}race.mp4"
        if [ -f "$src" ]; then
            echo "$src"
            if [ -n "$stretch" ]; then
                src_src="$src"
                src="${prefix}race_stretch.mp4"
                cmd.exe /c "..\\ffmpeg.exe -i $src_src -vf tpad=stop=180:stop_mode=clone $src"    
            fi

            ffmpeg -i "$src" -vf crop=640:400:0:0 -r 60 "$dist/${prefix}race_0.mp4"
            ffmpeg -i "$src" -vf crop=640:400:640:0 -r 60 "$dist/${prefix}race_1.mp4"
            ffmpeg -i "$src" -vf crop=640:400:0:400 -r 60 "$dist/${prefix}race_2.mp4"
            ffmpeg -i "$src" -vf crop=640:400:640:400 -r 60 "$dist/${prefix}race_3.mp4"
        else
            echo "$src not found"
        fi
    done
    IFS="$IFS_back"


# muxMovie </path/to/movie> <divider>
# divider:  1.00 or 0.99
elif [ "$1" == "muxMovie" ]; then
    movie="$2"
    divider="$3"
    cd "$movie"
    IFS_back="$IFS"
    IFS=$'\n'
    for line in `cat "$ETROBO_ROOT/dist/cs_order.txt"`; do
        teamID="`echo $line | awk '{print $1}'`"
        selectL="`echo $line | awk '{print $2}'`"
        selectR="`echo $line | awk '{print $3}'`"
        selectBest="`echo $line | awk '{print $4}'`"
        order="0`echo $line | awk '{print $5}'`"
        class="${teamID:0:1}"
        teamNo="${teamID:1:3}"
        prefix="${class}-${order:${#order}-2}B_${teamNo}_"
        
        if [ -f "${prefix}race_0.mp4" ]; then
            echo "${prefix}race_mux.mp4"
            ffmpeg	-i "${prefix}mm.mp4" -i "${prefix}race_1.mp4" -i "${prefix}race_2.mp4" -i "${prefix}race_3.mp4" \
                -filter_complex " \
                    color=s=1280x800:c=black [base]; \
                    [0:v] scale=640x400:force_original_aspect_ratio=decrease [upperleft]; \
                    [1:v] setpts=PTS/$divider, scale=640x400 [upperright]; \
                    [2:v] setpts=PTS/$divider, scale=640x400 [lowerleft]; \
                    [3:v] setpts=PTS/$divider, scale=640x400 [lowerright]; \
                    [base][upperleft] overlay=shortest=1:x=40 [tmp1]; \
                    [tmp1][upperright] overlay=shortest=1:x=640 [tmp2]; \
                    [tmp2][lowerleft] overlay=shortest=1:y=400 [tmp3]; \
                    [tmp3][lowerright] overlay=shortest=1:x=640:y=400 \
                " \
            	-r 60 ${prefix}race_mux.mp4
        else
            echo "$src not found"
        fi
    done
    IFS="$IFS_back"

# getBlockPng </path/to/result> </path/to/result_rerun> [rev]
elif [ "$1" == "getBlockPng" ]; then
    result="$2"
    result_rerun="$3"
    rev="$4"
    if [ -z "$rev" ]; then
        dist="${result}_block"
        selector="L"
        zPost="B"
    else
        dist="${result}_block_rev"
        selector="R"
        zPost="R"
    fi
    if [ ! -d "$dist" ]; then
        mkdir "$dist"
    fi
    while read line; do
        teamID="`echo $line | awk '{print $1}'`"
        selectL="`echo $line | awk '{print $2}'`"
        selectR="`echo $line | awk '{print $3}'`"
        selectBest="`echo $line | awk '{print $4}'`"
        order="0`echo $line | awk '{print $5}'`"
        class="${teamID:0:1}"
        teamNo="${teamID:1:3}"
        prefix="${class}-${order:${#order}-2}${zPost}_${teamNo}_"
        if [ "$selectL" == "前" ]; then
            folderL="$result/${teamID}_L"
        else
            folderL="$result_rerun/${teamID}_L"
        fi
        if [ "$selectR" == "前" ]; then
            folderR="$result/${teamID}_R"
        else
            folderR="$result_rerun/${teamID}_R"
        fi
        if [ "${selectBest:0:1}" == "$selector" ]; then
            raceID="${teamID}_L"
            folderBest="$folderL"
        else
            raceID="${teamID}_R"
            folderBest="$folderR"
        fi
        
        for target in `ls -1 "$folderBest"/*ブロック配置.png`; do
            cp "$target" "$dist/${prefix}block.png"
        done
    done < "$ETROBO_ROOT/dist/cs_order.txt"

else
    echo "usage:"
    echo "  prepare_final.sh expand </path/to/Datum>"
    echo "  prepare_final.sh spread </path/to/Results>"
    echo "  prepare_final.sh changeFps </path/to/up_sim> [reencode <divider>] <fps>"
    echo "  prepare_final.sh updateResult </path/to/up_sim>"
    echo "  prepare_final.sh getCsv </path/to/up_sim>"
fi

# oneliners
#for target in `ls -1`; do dist="`echo $target | sed -E 's/^(.)-.*_(.*)_race_mux.mp4/\1\2.mp4/'`"; echo "$target -> $dist"; mv $target $dist; done
