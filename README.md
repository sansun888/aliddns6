# 支持 IPv6 的 aliddns.sh

aliddns.sh，想要做到一个脚本全平台可运行。

已在 Windows7、Manjaro、RT-AC86U、Termux、RPi 4B 中测试通过。

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

## 3. 下载脚本并配置

1. 下载本仓库中的脚本 [aliddns.sh](https://gitee.com/tyasky/aliddns6/releases)。

2. 修改脚本开始的以下参数

    前四行必改，后四行选改。在 Windows 下推荐用 [Notepad++](https://notepad-plus-plus.org/downloads/)  修改，不要用记事本。

    ```bash
    ak="Access Key ID"
    sk="Access Key Secret"
    host="test"
    domain="example.com"
    
    rungap=300             # 更新间隔秒数
    type=AAAA              # 解析记录类型
    downvalue=""           # 解析值，留空则动态获取
    dns="dns9.hichina.com"
    ```

## 4. 路由器中自动运行

下面的步骤在 Windows 下可用 [WinSCP](https://winscp.net/) 完成。

假设路由器中已开启 SSH，端口号为 8022，路由器登录名为 Asus，路由器 IP 为 192.168.50.1。

以下第二步和第三步是 SSH 进路由器中完成的。

1. 将本脚本放到 `/jffs/`目录下

    ```bash
    scp -P8022 ./aliddns.sh Asus@192.168.50.1:/jffs/
    ```

2. 添加执行权限

    ```bash
    chmod a+x /jffs/aliddns.sh
    ```

3. 在 `/jffs/scripts/services-start` 末尾添加一行

    ```bash
    source /jffs/aliddns.sh &
    ```

4. 重启路由器。

## 5. Windows7 下运行

1. 下载安装 [Git](https://git-scm.com/download/win)，提供一个脚本运行环境。

2. 双击脚本运行

## 6. 命令行运行

1. 指定配置文件运行

    有配置文件 conf.txt，内容如下（其实就是将 aliddns.sh 中的配置内容复制到新的文件）：

    ```bash
    ak="Access Key ID"
    sk="Access Key Secret"
    host="test"
    domain="example.com"

    rungap=300             # 更新间隔秒数
    type=AAAA              # 解析记录类型
    downvalue=""           # 解析值，留空则动态获取
    dns="dns9.hichina.com"
    ```

    可这样运行：

    ```bash
    ./aliddns.sh -f conf.txt
    ```

2. 删除解析记录

    主域名是 xx.com，删除 test.xx.com 的解析记录：

    ```bash
    ./aliddns.sh -f conf.txt -d test
    ```

3. 后台运行

    ```bash
    nohup ./aliddns.sh &
    ```

## 6. 其他

[检查域名解析情况](https://zijian.aliyun.com/)。

[阿里云云解析 DNS API 文档](https://help.aliyun.com/document_detail/29740.html)。

交流反馈扣扣群：585194793
