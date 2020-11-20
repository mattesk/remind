#!/bin/bash

#
# remind.sh
#

VERSION=002

REMIND_TEST=

LOG="/tmp/remind.log"
#SENDER="remind_mykmk <remind@mykmk.com>"
SENDER="BIRTHDAY reminder <remind@mykmk.com>"

function reminder_mail()
{
   recipient=$1
   mSubject=$2
   mBody=$3

   if [ ! -z "$REMIND_TEST" ]; then
      # test mode is enable
      echo "   "$REMIND_SUBJECT $mSubject"     !!!TEST mode active, no email"
      return;
   fi

   echo "   remind $1 of $2"
   echo $mBody | /bin/mail -s "$REMIND_SUBJECT $mSubject" -r "$SENDER" -c "" -b "" $recipient >>$LOG 2>&1

}

REMIND_RECIPIENT=
REMIND_SUBJECT=
REMIND_TIME=

set_recipient()
{
   REMIND_RECIPIENT=$2
}

set_subject()
{
   REMIND_SUBJECT=$2
}

set_remindtime()
{
   REMIND_TIME=$2
}

set_par()
{
   # strip first char
   par="${1:1}"

   #echo p: $par

   case "$par" in
    text:*)
            echo "text:"$par 
            ;;
    subject:*)
            echo "text:"$par 
            set_subject $par
            ;;
    time:*)
            echo "text:"$par 
            set_remindtime $par
            ;;
    m*)
            echo "mail" $par
            set_recipient $par
            ;;
    c*)
            echo "cc" $par 
            ;;
     *)
            echo "unsupported: "$par ;;
   esac
}

reminder_line()
{
  # reminder line format: date time data 
  # $1 date
  # $2 time
  # $3 text 

  #echo rl: $1 $2 $3 $4

  rdat=$1
  rtim=$2
  shift 2
  rtx=$@
  #echo rd/t/tx: $rd $rt $rtx

  today=$(date +"%s")
  currentYear=$(date +"%Y")
  birthdayThisYear="$currentYear${rdat:4:6}"

  # convert date to timestamp
  # date -d '2012-06-12 7:21:22' +"%s"
  datim="$rdat $rtim"
  datim="$birthdayThisYear $rtim"
  ts=$(date -d "${datim}" +"%s")
  time2pass=$(expr $ts - $today)

  #if [[ $time2pass -lt 0 ]]; then
  if [[ $time2pass -lt -86400 ]]; then
     # add a year
     echo  time2pass in NEG $time2pass
     nextYear=$(expr $currentYear + 1)
     birthdayNextYear="$nextYear${rdat:4:6}"
     datim="$birthdayNextYear $rtim"
     ts=$(date -d "${datim}" +"%s")
     time2pass=$(expr $ts - $today)
  fi

  time2birthday=$(expr $time2pass + 86400)
  daysleft=$(expr $time2birthday / 86400)
  remainder=$(expr $time2birthday % 86400)
  hoursleft=$(expr $remainder / 3600)

  echo  $datim  ${daysleft}d.${hoursleft}h $rtx

  #if [[ $daysleft -eq 0 ]]; then
  #   reminder_mail $REMIND_RECIPIENT "$rtx TODAY" "it's $rtx birthday $datim"  
  #elif [[ $daysleft -lt 2 ]]; then
  #   reminder_mail $REMIND_RECIPIENT "BD $rtx" "it's $rtx birthday $datim"  
  #fi
  if [[ $time2pass -lt 0 ]]; then
     reminder_mail $REMIND_RECIPIENT "$rtx TODAY" "it's $rtx birthday $datim"  
  elif [[ $time2pass -lt 86400 ]]; then
     reminder_mail $REMIND_RECIPIENT "$rtx tommorow" "it's $rtx birthday $datim"  
  elif [[ $time2pass -lt 172800 ]]; then
     reminder_mail $REMIND_RECIPIENT "$rtx in $daysleft days" "it's $rtx birthday $datim"  
  fi
}

parse_reminder()
{
   input=$1

   REMIND_RECIPIENT=
   REMIND_SUBJECT=
   REMIND_TIME=-1

   while IFS= read -r line
   do

      #
      # if value of $var starts with #, ignore it
      #
      [[ $line =~ ^#.* ]] && continue
      #  [ -z "$line" ] && echo "Empty"
      [ -z "$line" ] && continue

      [[ $line =~ ^\$.* ]] && set_par "$line" && continue

      #if [[ $REMIND_TIME -ge 0 ]]; then
      if [ ! -z "$REMIND_TIME" ]; then
          timnow=$(date +"%s")
          today=$(date +"%Y-%m-%d")
          datim="$today $REMIND_TIME"
          #datim="$today 0:0:0"
          ts=$(date -d "${datim}" +"%s")
          #ts=$(expr $ts + $REMIND_TIME)
          time2remind=$(expr $ts - $timnow)
          echo "    +++ $today +++ $time2remind --- REMINDTIME is set $REMIND_TIME"
          # check if it is time to process list
          #    we run every 60sec, make sure we trigger 
          #if [[ $time2remind -lt 60 ]] && [[ $time2remind -ge 0 ]] ; then
          if [[ $time2remind -le 0 ]] && [[ $time2remind -ge -59 ]] ; then
             echo "    --- it is TIME to REMIND  $REMIND_TIME ($time2remind sec)"
          else
             echo "    --- REMINDTIME is set $REMIND_TIME in $time2remind seconds"
             return
          fi
      fi

      # must a reminder line   date time data 
      #echo "$line"
      reminder_line $line

   done < "$input"

}

check_reminder()
{
   rfolder=$1

   for file in $rfolder/*.remind
   do
      echo === remind ====== $file
      parse_reminder $file
   done

}


#
# this is main
#

REMIND_FOLDER=/usr/local/remind

# if arg pass rfile
#rfile=$1
#parse_reminder $rfile

if [ $# -gt 0 ]; then
    echo "WE have arguments supplied"
   REMIND_TEST=$1
fi

if [ -z "$REMIND_TEST" ]; then
   sleep 10
   #sleep 120
fi

while : ; do
   check_reminder $REMIND_FOLDER

   if [ ! -z "$REMIND_TEST" ]; then
      # test mode is enable
      exit
   fi

   sleep 60
done


# Split string into an array in Bash
# https://stackoverflow.com/questions/10586153/split-string-into-an-array-in-bash
#string='Paris, France, Europe';
#readarray -td, a <<<"$string"; declare -p a;
### declare -a a=([0]="Paris" [1]=" France" [2]=$' Europe\n')


