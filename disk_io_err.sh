#!/bin/sh
# Copyright (c) 2014 Ruben Kelevra
#
# Licence: AGPL 3.0
#
#%# family=manual

disks=('sda' 'sdb' 'sdc' 'sdd' 'sde') #define disks
value=-2
log_file='/tmp/munin_plugin_disk_ioerr.log'
time_file='/tmp/munin_plugin_disk_ioerr.time'
time_arg=''
tmp=''

if [ "$1" = "config" ]; then
	echo "graph_title Disk I/O-Errors"
	echo 'graph_args -l 0 --upper-limit 10'
        echo 'graph_vlabel err / 5min'
        echo 'graph_category disk'
	echo 'graph_info This graph shows disk I/O-Errors logged by Kernel'
        

	for (( i = 0 ; i < ${#disks[@]} ; i++ ))
	do
		echo "${disks[$i]}.label IO-ERR for /dev/${disks[$i]}"
		echo "${disks[$i]}.info io-err for /dev/${disks[$i]}."
	done
	echo "other.label other IO-ERR"
	echo "other.info IO-ERR for not definied devices"
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

eval journalctl --no-pager -k -o cat -p 3 $time_arg 2>/dev/null | grep "end_request: I/O error" > $log_file

tmp=''

for (( i = 0 ; i < ${#disks[@]} ; i++ ))
do
	value=-1
	value=`cat $log_file | grep "dev ${disks[$i]}" | wc -l` 
	echo "${disks[$i]}.value $value"
	if [ $i -eq 0 ]; then
		tmp="dev ${disks[$i]}"
	else
		tmp="$tmp|dev ${disks[$i]}"
	fi
done

value=-1
value=`cat $log_file | grep -vE "$tmp" | wc -l`
echo "other.value $value"

rm $log_file
