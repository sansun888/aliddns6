#!/usr/bin/env bash

# Author: tyasky

ak="Access Key ID"
sk="Access Key Secret"
host="test"
domain="example.com"

runnum=3               # 最多尝试更新次数
rungap=60              # 尝试间隔秒数
type=AAAA              # 解析记录类型
downvalue=""           # 解析值，留空则动态获取
dns="dns9.hichina.com"


# 存在 ip 就用 ip，否则用 ipconfig
which ip>/dev/null 2>&1
if [ $? -eq 0 ];then
    get_downvalue() {
        ((ip -6 addr|grep temporary)||(ip -6 addr|grep dynamic)|tail -1)|awk '{print $2}'|awk -F/ '{print $1}'
    }
else
    get_downvalue() {
        ipconfig|iconv -f gbk -t UTF-8|grep '临时 IPv6'|head -1|awk '{print $NF}'
    }
fi

# 第二个参数指定额外不编码的字符
# 笔记：[-_.~a-zA-Z0-9$2] 中的-字符用于表示区间，放到中间会出意外结果
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o
    for pos in $(awk "BEGIN { for ( i=0; i<$strlen; i++ ) { print i; } }")
    do
        c=${string:$pos:1}
        case $c in
            [-_.~a-zA-Z0-9$2] ) o="${c}" ;;
            * ) o=`printf '%%%02X' "'$c"`
        esac
        encoded="$encoded$o"
     done
     echo "${encoded}"
}

send_request() {
    timestamp=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
    # 服务器拒绝重放攻击（本次与前一次请求数据相同返回错误)，SignatureNonce 需赋值随机数而不能是时间戳(可能同一秒两次请求)
    nonce=`openssl rand -base64 8 | md5sum | cut -c1-8`
    args="AccessKeyId=$ak&Format=json&SignatureMethod=HMAC-SHA1&SignatureNonce=$nonce&SignatureVersion=1.0&Timestamp=$timestamp&Version=2015-01-09&$1"
    # 签名要求参数按大小写敏感排序(sort 在本地语言环境可能会忽略大小写排序)：LC_ALL=c sort
    args=`echo $args | sed 's/\&/\n/g' | LC_ALL=c sort | xargs | sed 's/ /\&/g'`
    CanonicalizedQueryString=$(urlencode $args "=&")
    StringToSign="GET&%2F&$(urlencode $CanonicalizedQueryString)"
    Signature=$(urlencode $(echo -n "$StringToSign" | openssl dgst -sha1 -hmac "$sk&" -binary | openssl base64))
    echo $(curl -k -s "https://alidns.aliyuncs.com/?$args&Signature=$Signature")
}

getValueFromJson() {
    local json="$1"
    local key="$2"
    echo $json | sed 's/":/：/g;s/"//g;s/,/\n/g' | grep $key | awk -F： '{ print $2 }'
}

DescribeSubDomainRecords() {
    send_request "Action=DescribeSubDomainRecords&SubDomain=$host.$domain"
}

UpdateDomainRecord() {
    local recordid=$(getValueFromJson `DescribeSubDomainRecords` "RecordId")
    send_request "Action=UpdateDomainRecord&RR=$host&RecordId=$recordid&Type=$type&Value=$downvalue"
}

AddDomainRecord() {
    send_request "Action=AddDomainRecord&DomainName=$domain&RR=$host&Type=$type&Value=$downvalue"
}

DeleteSubDomainRecords() {
    send_request "Action=DeleteSubDomainRecords&DomainName=$domain&RR=$host"
}

usage() {
    echo "Usage:"
    echo "-f file1  Read config from file1" 
    echo "-d test   DeleteSubDomainRecords of test.xx.com"
    echo "-h        Show usage"
    exit
}

set -- $(getopt -q hd:f: "$@")
while [ -n "$1" ]
do
    case "$1" in
        -h) usage;;
        -d) host=${2:1:!2-1};DeleteSubDomainRecords;exit;;
        -f) . ${2:1:!2-1};shift;;
        *);;
    esac
    shift
done

while [ $runnum -gt 0 ]
do
    runnum=$(expr $runnum - 1)
    datetime=$(date +%Y-%m-%d\ %T)
    echo 当前时间：$datetime

    rslt=`DescribeSubDomainRecords`
    if [ -z "$rslt" ];then
        echo "未获取到阿里云查询结果"
        sleep $rungap
        continue
    fi
    upvalue=$(getValueFromJson "$rslt" "Value")
    echo 域名指向：$upvalue

    downvalue=${downvalue:=`get_downvalue`}
    if [ -z "$downvalue" ]; then
        echo "未获取到本机地址"
        sleep $rungap
        continue
    fi
    echo 本机地址：$downvalue

    if [ "$upvalue" = "$downvalue" ]; then
        echo "已正确解析，无需更新。"
    elif [ -n "$upvalue" ]; then
        echo "更新解析记录..."
        UpdateDomainRecord
    else
        echo "添加解析记录..."
        AddDomainRecord
    fi
    break
done
