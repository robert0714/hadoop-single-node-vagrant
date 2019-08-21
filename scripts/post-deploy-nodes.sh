#!/bin/bash
value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ hadoop-cookbook host entry ############
10.100.192.100  master
10.100.192.101  data-1
10.100.192.102  data-2
10.100.192.103  data-3
######################################################
" >> /etc/hosts

