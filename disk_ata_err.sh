#!/bin/sh
# Copyright (c) 2014 Ruben Kelevra
#
# Licence: AGPL 3.0
#
#%# family=manual

disks=('sda' 'sdb' 'sdc' 'sdd' 'sde') #define disks 
value=-2
log_file='/tmp/munin_plugin_ata_err.log'
time_file='/tmp/munin_plugin_ata_err.time'
time_arg=''
tmp=''

if [ "$1" = "config" ]; then
	echo "graph_title ATA-Errors"
	echo 'graph_args -l 0 --upper-limit 10'
        echo 'graph_vlabel err / 5min'
        echo 'graph_category disk'
	echo 'graph_info This graph shows ATA-Errors logged by Kernel'
        

	for (( i = 0 ; i < ${#disks[@]} ; i++ ))
	do
		echo "${disks[$i]}.label ATA-ERR for /dev/${disks[$i]}"
		echo "${disks[$i]}.info ATA-err for /dev/${disks[$i]}."
	done
	echo "other.label other ATA-ERR"
	echo "other.info ATA-ERR for not definied devices"
        exit 0
fi

if [ ! -f $time_file ]; then
	time_arg='-b 0'
else
	time_arg=`cat $time_file`
	time_arg=`echo "--since=\"$time_arg\""`
fi

eval journalctl --no-pager -k -o cat -p 3 $time_arg 2>/dev/null > /dev/null

tmp=`date --rfc-3339="seconds"`
echo "${tmp:0:19}" > $time_file

eval journalctl --no-pager -k -o cat -p 3 $time_arg 2>/dev/null | grep "^ata" | grep "error: { " > $log_file

tmp=''
atano=''

for (( i = 0 ; i < ${#disks[@]} ; i++ ))
do
        value=-1
	#atano=`ls -l /sys/block/sd* | grep "${disks[$i]}" | awk '{ print $11 }' | sed -e 's/\// /g' | awk '{ print $5 }'`
	atano=`ls -l /sys/block/sd* | grep "${disks[$i]}" | sed -e 's/\//\n/g' | grep -E "^ata|^usb"`
        value=`cat $log_file | grep "^$atano." | wc -l` 
        echo "${disks[$i]}.value $value"
        if [ $i -eq 0 ]; then
                tmp="^$atano."
        else
                tmp="$tmp|^$atano."
        fi
done

value=-1
value=`cat $log_file | grep -vE "$tmp" | wc -l`
echo "other.value $value"

rm $log_file
