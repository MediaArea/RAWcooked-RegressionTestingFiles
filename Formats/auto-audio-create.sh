for F in {aiff,wav}; do
    for f in {44100,48000,96000}; do
        for b in {8,16,24,32,64}; do
            for c in {1,2,4,6,8}; do
                for x in {f,s,u}; do
                    if [ $b -lt 32 ] && [ "$x" == "f" ]; then
                        continue
                    fi
                    if [ $b -gt 8 ] && [ "$x" == "u" ]; then
                        continue
                    fi
                    for e in {_be,_le}; do
                        if [ $b -eq 8 ]; then
                            e=""
                        fi
                        dirname=${F^^}/Flavors/${f}_${b}_${c}_${x^}${e^^}
                        filename=${f}_${b}_${c}_${x^}${e^^}.${F}
                        mkdir $dirname
                        ffmpeg -y -f lavfi -i "sine=frequency=1000:sample_rate=${f}:duration=0.1" -c:a pcm_${x}${b}${e:1} -ac ${c} $dirname/$filename
                        if [ ! -f $dirname/$filename ]; then
                            rmdir $dirname
                        elif [ $(wc -c $dirname/$filename | awk '{print $1}') -lt 2000 ]; then
                            rm $dirname/$filename
                            rmdir $dirname
                        fi
                        if [ $b -eq 8 ]; then
                            break
                        fi
                    done
                done
            done
        done
    done
done