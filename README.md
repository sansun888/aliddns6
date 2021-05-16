# 支持 IPv6 的 aliddns.sh

为了兼容，只留下一个可独立运行的脚本 aliddns.sh。此脚本已在 Manjaro、RT-AC86U、Termux 中测试过了。

## 1. 测试是否已接入 IPv6 网络

[IPv6 测试](http://www.test-ipv6.com/)，成功接入 IPv6 网络显示如下：

![test-ipv6](./images/test-ipv6.png)

如果没接入 IPv6 网络，参考[电信获取ipv6](https://m.ithome.com/html/405571.htm)。

## 2. 准备域名

去阿里云[万网](https://wanwang.aliyun.com/)购买一个域名。需要实名认证，购买域名时要填真实信息。

域名购买成功后，登录阿里云，进入控制台，[RAM 访问控制](https://ram.console.aliyun.com/overview)。用户 ➡️ 创建用户：

![createuser](./images/createuser.png)

图中勾选了**编程访问**，会生成 **AccessKey ID** 和 **AccessKey Secret**：

![idsecret](./images/idsecret.png)

为新加的用户添加权限 **AliyunDNSFullAccess**：

![dnsfullaccess](./images/dnsfullaccess.png)

## 3. 添加解析脚本

下载本仓库中的脚本 aliddns.sh。

下面的步骤在 Windows 下可以用 [WinSCP](https://winscp.net/) 完成。

1. 修改脚本开始的以下参数

    ```bash
    ak="Access Key ID"
    sk="Access Key Secret"
    host="test"
    domain="example.com"
    rungap=300                # 更新解析记录的间隔时间，秒数
    ```

2. 将本脚本放到 `/jffs/`目录下

    ```bash
    scp -P8022 ./aliddns.sh RouterLoginName@192.168.50.1:/jffs/
    ```

3. 添加执行权限

    ```bash
    chmod a+x /jffs/aliddns.sh
    ```

4. 在 `/jffs/scripts/wan-start`末尾添加一行

    ```bash
    source /jffs/aliddns.sh
    ```

5. 重启路由器。

## 4. 其他

[检查域名解析情况](https://zijian.aliyun.com/)。

[阿里云云解析 DNS API 文档](https://help.aliyun.com/document_detail/29740.html)。