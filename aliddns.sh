#!env bash

# Author: tyasky

ak="Access Key ID"
sk="Access Key Secret"
host="test"
domain="example.com"
rungap=300             # 更新间隔秒数

dns="dns9.hichina.com"
type=AAAA              # 解析记录类型
downvalue=""           # 解析值，留空则动态获取
get_downvalue() {
    ip -6 address | grep dynamic | tail -1 | awk '{print $2}' | awk -F '/' '{print $1}'
}


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
    Signature=$(urlencode $(echo -n "$StringToSign" | openssl dgst -sha1 -hmac "$sk&" -binary | base64))
    echo $(curl -k -s "https://alidns.aliyuncs.com/?$args&Signature=$Signature")
}

query_recordid() {
    send_request "Action=DescribeSubDomainRecords&SubDomain=$host.$domain" | sed 's/":/：/g;s/"//g;s/,/\n/g' | grep RecordId | awk -F： '{ print $2 }'
}

query_value() {
    send_request "Action=DescribeSubDomainRecords&SubDomain=$host.$domain" | sed 's/":/：/g;s/"//g;s/,/\n/g' | grep Value | awk -F： '{ print $2 }'
}

update_record() {
    send_request "Action=UpdateDomainRecord&RR=$host&RecordId=$(query_recordid)&Type=$type&Value=$downvalue"
}

add_record() {
    send_request "Action=AddDomainRecord&DomainName=$domain&RR=$host&Type=$type&Value=$downvalue"
}

delete_record() {
    send_request "Action=DeleteDomainRecord&RecordId=$(query_recordid)"
}

while [ 1 -eq 1 ]
do
    datetime=$(date +%Y-%m-%d\ %T)
    echo 当前时间：$datetime

    upvalue=`query_value`
    echo 域名指向：$upvalue

    downvalue=${downvalue:=`get_downvalue`}
    echo 本机地址：$downvalue

    if [ -z "$downvalue" ]; then
        echo "未获取到本机地址"
        sleep $rungap
        continue
    fi

    if [ "$upvalue" = "$downvalue" ]; then
        echo "已正确解析，无需更新。"
    elif [ -n "$upvalue" ]; then
        echo "更新解析记录..."
        update_record
    else
        echo "添加解析记录..."
        add_record
    fi
    sleep $rungap
done
