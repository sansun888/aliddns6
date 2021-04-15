#!/bin/sh

source /koolshare/scripts/base.sh
eval `dbus export aliddns6_`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】'
https_lanport=`nvram get https_lanport`
if [ "$aliddns6_enable" != "1" ]; then
	nvram set ddns_hostname_x=`nvram get ddns_hostname_old`
	echo "not enable"
	exit
fi	

now=`echo_date`

die () {
	echo $1
	dbus set aliddns6_last_act="$now: failed($1)"
}

# [ "$aliddns6_curl" = "" ] && aliddns6_curl="ip -6 address | grep dynamic | awk '{print $2}' | awk -F '/' '{print $1}'"
[ "$aliddns6_dns" = "" ] && aliddns6_dns="223.5.5.5"
[ "$aliddns6_ttl" = "" ] && aliddns6_ttl="600"

# 本地 ip
# ip=`$aliddns6_curl 2>&1` || die "$ip"

ip=`ip -6 address | grep dynamic | awk '{print $2}' | awk -F '/' '{print $1}' 2>&1` || die "$ip"
# 记录类型 type，根据 curl 到的 ip 设定 type
[ `echo $ip |grep -oE '[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}' |wc -l` -ne 0 ] && type="A" || type="AAAA"

#support @ record nslookup
if [ "$aliddns6_name" = "@" ];then
	current_ip=`nslookup $aliddns6_domain $aliddns6_dns 2>&1`
else
	current_ip=`nslookup $aliddns6_name.$aliddns6_domain $aliddns6_dns 2>&1`
fi

if [ "$type" = "A" ];then
	current_ip=`echo "$current_ip" | grep 'Address' | awk 'NR>1{print $3}' | awk '/\./ {print $1}'`
else
	current_ip=`echo "$current_ip" | grep 'Address' | awk 'NR>1{print $3}' | awk '/:/ {print $1}'`
fi

if [ "$?" -eq "0" ];then
	if [ "$ip" = "$current_ip" ]
	then
		echo "skipping"
		dbus set aliddns6_last_act="$now: skipped($ip)"
		nvram set ddns_enable_x=1
		#web ui show without @.
		if [ "$aliddns6_name" = "@" ] ;then
			nvram set ddns_hostname_x="$aliddns6_domain"
		else
			ddns_custom_updated 1
			exit 0
		fi
	fi 
else
	# fix when A record removed by manual dns is always update error
	unset aliddns6_record_id
fi


############################### 外部引入代码 start ##################################
##配置

host="$aliddns6_name"      # 主机名
domain="$aliddns6_domain"  # 域名
ak="$aliddns6_ak"          # 阿里云AccessKey ID
sk="$aliddns6_sk&"         # 阿里云Access Key Secret  后面多个 &
type="$type"
timestamp=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

##############################
#hash签名使用
urlencode1() {
    local length="${#1}"
    i=0
    out=""
    for i in $(awk "BEGIN { for ( i=0; i<$length; i++ ) { print i; } }")
    do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~'&'=_-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
        i=$(($i + 1))
     done
     echo -n $out
}
urlencode2() {
    local length="${#1}"
    i=0
    out=""
    for i in $(awk "BEGIN { for ( i=0; i<$length; i++ ) { print i; } }")
    do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
        i=$(($i + 1))
     done
     echo -n $out
}

##############################
#函数

send_request() {   
    args="AccessKeyId=$ak&Action=$1&Format=json&$2&Version=2015-01-09"
    StringToSign1="$(urlencode1 $args)"
    StringToSign2="GET&%2F&$(urlencode2 $StringToSign1)"
    hash=$(urlencode2 $(echo -n "$StringToSign2" | openssl dgst -sha1 -hmac $sk -binary | openssl base64))
    RESULT=$(curl -k -s "https://alidns.aliyuncs.com/?$args&Signature=$hash")  ## 2> /dev/null)
    echo $RESULT
}
query_recordid() {
    if [ "$host" = "@" ]; then 
        echo `send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$domain&Timestamp=$timestamp"`
    else
        echo `send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$host.$domain&Timestamp=$timestamp"`
    fi
}
update_record() {
    echo `send_request "UpdateDomainRecord" "RR=$host&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&Timestamp=$timestamp&Type=$type&Value=$ip"`
}
add_record() {
    echo `send_request "AddDomainRecord&DomainName=$domain" "RR=$host&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&Timestamp=$timestamp&Type=$type&Value=$ip"`
}

add_host() {
    # echo "新增解析"
    RESULT=`add_record`
    record_id=$(echo $RESULT | grep -o "RecordId\":\"[0-9]*\"" | grep -o "[0-9]*")
    [ "$record_id" = "" ] && { echo "$host.$domain  $ip  AddError";exit 1; }
    echo "$host.$domain  $ip  AddHost $(date +'%F %T')"
}

up_host() {
    # echo "更新解析"
    # 查询RecordId
    echo $timestamp
    echo $host
    echo $domain
    RESULT=`query_recordid`
    echo $RESULT
    record_id=$(echo $RESULT | grep -o "RecordId\":\"[0-9]*" | grep -o "[0-9]*")
    [ "$record_id" = "" ] && { echo "get record_id error";exit 1; }
    # 更新
    RESULT=`update_record $record_id`
    record_id=$(echo $RESULT | grep -o "RecordId\":\"[0-9]*\"" | grep -o "[0-9]*")
    [ "$record_id" = "" ] && { echo "$host.$domain  $ip  UpError";exit 1; }
    echo "$host.$domain    $ip  UpHost $(date +'%F %T')"
}


#传参  主机 域名 ip

alidns() {
    # var:  host domain ip
    host="$1"
    domain=$2
    ip=$3
    ip_dns="$current_ip"

    if [ $# -eq 2 ];then
        if [ -n "$ip_dns" ];then
            echo "$host.$domain    $ip_dns"
        else
            echo "$host.$domain  no found"
        fi
    elif [ $# -eq 3 ];then
        if [ "$ip" = "$ip_dns" ];then
            echo "$host.$domain    $ip_dns"
        else
            [ "$ip_dns" = "" ] && { add_host ; } || { up_host ; }
        fi
    else
        echo "eg:$0  www  abc.com  192.168.18.18"
    fi
}

# alidns "$@"   # 外部参数传给主函数处理

############################### 外部引入代码 end ####################################

# 调用主函数
alidns $host $domain $ip

####### save to file start ########

aliddns6_record_id="$record_id"
if [ -z "$aliddns6_record_id" ]; then
	# failed
	dbus set aliddns6_last_act="$now: failed"
	nvram set ddns_hostname_x=`nvram get ddns_hostname_old`
else
	dbus set aliddns6_record_id="$aliddns6_record_id"
	dbus set aliddns6_last_act="$now: success($ip)"
	nvram set ddns_enable_x=1
	#web ui show without @.
	if [ "$aliddns6_name" = "@" ] ;then
	 	nvram set ddns_hostname_x="$aliddns6_domain"
		nvram set ddns_updated="1"
		nvram commit
	else
	 	nvram set ddns_hostname_x="$aliddns6_name"."$aliddns6_domain"
		nvram set ddns_updated="1"
		nvram commit
	fi
fi
####### save to file end ########
