#!/bin/bash
for Channel in {1..8}; do
  SineFreq=$(expr ${Channel} \* 1000)
  ffmpeg -y -f lavfi -i sine=frequency=${SineFreq}:sample_rate=42336000:duration=2 -c:a pcm_f64be temp_ch${Channel}temp.aiff
  ffmpeg -y -i temp_ch${Channel}temp.aiff -af "volume=-1dB" temp_ch${Channel}.aiff
  rm temp_ch${Channel}temp.aiff
done

for Format in aiff wav; do
  for Frequency in 44100 48000 96000; do
    Duration="2" #We want 65536 samples (max FLAC packet) for sure, but FFmpeg handles smaller packets so we adapt for 2 packets with minimal size
    if test $Frequency = "44100"; then
      Duration="0.110"
    fi
    if test $Frequency = "48000"; then
      Duration="0.100"
    fi
    if test $Frequency = "96000"; then
      Duration="0.090"
    fi
    for Channels in 1 2 6 8; do
      for BitDepth in 8 16 24 32 64; do
        for Sign in s u f; do
          for Endian in be le; do
            if test $BitDepth = "8"; then
              Endian=""
              EndianExtra=""
            else
              EndianExtra="_"
            fi
            Name=${Frequency}_${BitDepth}_${Channels}_${Sign^^}${EndianExtra}${Endian^^}.${Format}
            Fmt=pcm_${Sign}${BitDepth}${Endian}
            ChList=""
            for Ch in {1..${Channels}}; do
              ChList="${ChList}[$(expr ${Ch} - 1):a]"
            done
            if test ${Channels} -gt 2; then
              ChMain="$(expr ${Channels} - 1)"
              ChLfe=".1"
            elif test ${Channels} -gt 1; then
              ChMain="stereo"
              ChLfe=""
            else
              ChMain="mono"
              ChLfe=""
            fi
            ffmpeg -y -i temp_ch1.aiff -i temp_ch2.aiff -i temp_ch3.aiff -i temp_ch4.aiff -i temp_ch5.aiff -i temp_ch6.aiff -i temp_ch7.aiff -i temp_ch8.aiff -ar ${Frequency} -filter_complex "${ChList}join=inputs=${Channels}:channel_layout=${ChMain}${ChLfe}[a]" -map "[a]" -c:a $Fmt -t ${Duration} $Name
            FileSize=$(stat -c%s "$Name")
            if test "$FileSize" -gt 30; then
              Dir=../Formats/${Format^^}/Flavors/${Frequency}_${BitDepth}_${Channels}_${Sign^^}${EndianExtra}${Endian^^}
              mkdir -p ${Dir}
              mv -f $Name ${Dir}
            else
              rm $Name
            fi
          done
        done
      done
    done
  done
done

for Channel in {1..8}; do
  rm temp_ch${Channel}.aiff
done
