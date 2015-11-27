#!/bin/bash
#description:this script is to get network information
#date:2015-11-13
source /etc/profile

function byte_to_mb () {
	size=$1
	echo $(echo "scale=1;$size/1024/1024"|bc)M
}

function byte_to_Byte () {
	size=$1
	echo $(echo "scale=1;$size/1024"|bc)K
}

TCPDUMPBIN="/usr/sbin/tcpdump"
DATETIME=$(date +%Y%m%d%H%M%S)
DATADIR="/home/mtime/optools/netmonitor"
#开始抓取数据
$TCPDUMPBIN -i eth0 -G 60 -w $DATADIR/data/network_info_$DATETIME.pcap &>/dev/null

#开始分析数据
LOGFILE=$DATADIR/log/netmonitor_$DATETIME.log
#$TCPDUMPBIN -q -n -e -t -r $DATADIR/data/network_info_$DATETIME.pcap|sed 's#,# #g'|awk '{if($(NF-1)=="tcp") print $0}'|awk '{print $7"."$9}'|awk -F"." '{print $1"."$2"."$3"."$4,$6"."$7"."$8"."$9}' >$LOGFILE
$TCPDUMPBIN -q -n -e -t -r $DATADIR/data/network_info_$DATETIME.pcap|awk '{print $6,$7,$9}'|awk -F"[ :.]+" '{print $2"."$3"."$4"."$5,$7"."$8"."$9"."$10,$1}' >$LOGFILE

FILE=$LOGFILE
out_total=$(awk '{print $1,$3}' $FILE|awk '/10.10.1[1-3]0./'|awk '{a+=$2}END{print a}')
#echo $out_total
out_size=$(echo $(echo "scale=2;$out_total/1024/1024"|bc)M)
#byte_to_mb $out_total
#echo "out_size:$out_size"


in_total=$(awk '{print $2,$3}' $FILE|awk '/10.10.1[1-3]0./'|awk '{a+=$2}END{print a}')
#echo $in_total
in_size=$(echo $(echo "scale=2;$in_total/1024/1024"|bc)M)
#byte_to_Byte $in_total
#echo "in_size:$in_size"
HTTPMEG="<html> 
<body> 
<table width="60%" valign="middle"><tr><td>
<table border="1" align="center" width="60%"> 
<tr><td><b>out</b></td>
<td>总流量</td>
<td>$out_size</td>
</tr>
<tr> 
<td>源地址</td>
<td>目标地址</td>
<td>包数量</td>
<td>流量大小</td>
<td>总包数</td>
"

sou_ip=$(awk '{print $1}' $FILE|awk '/10.10.1[1-3]0./'|sort|uniq -c|sort -k1 -nr|awk '{print $2}'|head)
#arrsou_ip=($(awk '{print $1}' $FILE|sed -n 's#^\(10\.10\.1[1-3]0\..*$\)#\1#gp'|sort|uniq -c|sort -k1 -nr|head))
for s_ip in $sou_ip
do
	#total_s_ip=$(awk '{print $1}' $FILE|sed -n 's#^\(10\.10\.1[1-3]0\..*$\)#\1#gp'|sort|uniq -c|sort -k1 -nr|awk '{if($2=="'$s_ip'") print $1}')
	total_s_ip=$(awk '{print $1}' $FILE|grep -w "$s_ip"|wc -l)	
        b=($(awk '{if($1=="'$s_ip'") print $2}' $FILE|sort|uniq -c|sort -k1 -nr|head -1))
		#s_size=$(awk '{if($1=="'$s_ip'") print $3}' $FILE|awk '{p+=$1}END{print p}')
		s_size=$(awk '{if($1=="'$s_ip'") print $2,$3}' $FILE|awk '{S[$1]+=$2}END{for (k in S) print k,S[k]}'|sort -nr -k2|head -1|awk '{print $2}')
		if [ $s_size -gt 1024 ] && [ $s_size -lt 1048576 ];then
			fin_s_size=$(byte_to_Byte $s_size)
		else
			fin_s_size=$(byte_to_mb $s_size)
		fi
        HTTPMEG="$HTTPMEG <tr><td>$s_ip</td>"
        HTTPMEG="$HTTPMEG <td>${b[1]}</td>"
        HTTPMEG="$HTTPMEG <td>${b[0]}</td>"
		HTTPMEG="$HTTPMEG <td>$fin_s_size</td>"
        HTTPMEG="$HTTPMEG <td>$total_s_ip</td></tr>"
done

HTTPMEG="$HTTPMEG 
</tr> 
</table></td>
<td>
<table border="1" align="center" width="60%"> 
<tr><td><b>in</b></td>
<td>总流量</td>
<td>$in_size</td>
</tr>
</tr>
<tr> 
<td>源地址</td>
<td>目标地址</td>
<td>包数量</td>
<td>流量大小</td>
<td>包总数</td>
"
dsp_ip=$(awk '{print $2}' $FILE|awk '/10.10.1[1-3]0./'|sort|uniq -c|sort -k1 -nr|awk '{print $2}'|head)
#echo $dsp_ip
#arrdsp_ip=($(awk '{print $2}' $FILE|sed -n 's#^\(10\.10\.1[1-3]0\..*$\)#\1#gp'|sort|uniq -c|sort -k1 -nr|head))
for d_ip in $dsp_ip
do
	#total_d_ip=$(awk '{print $2}' $FILE|sed -n 's#^\(10\.10\.1[1-3]0\..*$\)#\1#gp'|sort|uniq -c|sort -k1 -nr|awk '{if($2=="'$d_ip'") print $1}') 
	total_d_ip=$(awk '{print $2}' $FILE|grep -w "$d_ip"|wc -l)
	a=($(awk '{if($2=="'$d_ip'") print $1}' $FILE|sort|uniq -c|sort -k1 -nr|head))
		#d_size=$(awk '{if($2=="'$d_ip'") print $3}' $FILE|awk '{q+=$1}END{print q}')
		d_size=$(awk '{if($2=="'$d_ip'") print $1,$3}' $FILE|awk '{S[$1]+=$2}END{for (k in S) print k,S[k]}'|sort -nr -k2|head -1|awk '{print $2}')
		if [ $d_size -gt 1024 ] && [ $d_size -lt 1048576 ];then
			fin_d_size=$(byte_to_Byte $d_size)
		else
			fin_d_size=$(byte_to_mb $d_size)
		fi
		HTTPMEG="$HTTPMEG <tr><td>${a[1]}</td>"
		HTTPMEG="$HTTPMEG <td>$d_ip</td>"
		HTTPMEG="$HTTPMEG <td>${a[0]}</td>"
		HTTPMEG="$HTTPMEG <td>$fin_d_size</td>"
		HTTPMEG="$HTTPMEG <td>$total_d_ip</td></tr>"
done

#echo $HTTPMEG|mutt -s "$(echo -e "db end 10M line monitor\nContent-Type: text/html;charset=utf-8")" zhenhong.sun@service.mtime.com

mailto=$(/bin/sh /home/mtime/optools/netmonitor/shell/getmaillist.sh)
echo $HTTPMEG|mutt -s "$(echo -e "db end 10M line monitor\nContent-Type: text/html;charset=utf-8")" $mailto


#删除临时文件
#rm -f 1.txt

#删除5个小时之前的数据
find $DATADIR -type f -name "network_info_*.pcap" -mmin +300|xargs rm -f
find $DATADIR -type f -name "netmonitor_*.log" -mmin +300|xargs rm -f

