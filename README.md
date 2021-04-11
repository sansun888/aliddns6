# 让 Aliddns 支持 IPv6

## 1. 测试是否已接入 IPv6 网络

[IPv6 测试](http://www.test-ipv6.com/)，成功接入 IPv6 网络显示如下：

![test-ipv6](./images/test-ipv6.png)

如果没接入 IPv6 网络，参考[电信获取ipv6][]。

## 2. 准备域名

去阿里云[万网](https://wanwang.aliyun.com/)购买一个域名。需要实名认证，购买域名时要填真实信息。

域名购买成功后，登录阿里云，进入控制台，[RAM 访问控制](https://ram.console.aliyun.com/overview)。用户 ➡️ 创建用户：

![createuser](./images/createuser.png)

图中勾选了**编程访问**，会生成 **AccessKey ID** 和 **AccessKey Secret**：

![idsecret](./images/idsecret.png)

为新加的用户添加权限 **AliyunDNSFullAccess**：

![dnsfullaccess](./images/dnsfullaccess.png)

## 3. 更换 Aliddns 中的脚本

用这里的`aliddns_update.sh`替换路由器`/koolshare/scripts/`目录下的`aliddns_update.sh`。

ssh进路由器，执行以下代码：
```zsh
cd /koolshare/script/
mv aliddns_update.sh aliddns_update.bak
wget https://gitee.com/tyasky/aliddns6/blob/master/aliddns_update.sh
chmod +x aliddns_update.sh
```

## 4. Aliddns 设置面板

我的固件是梅林改384.14，这是我的 Aliddns 设置界面:

![setting](./images/setting.png)

域名：任意英文名字，域名

DNS服务器：dns9.hichina.com 或者 dns10.hichina.com

获得 IP 命令：

```
curl -s v6.ident.me
```
此行代码可以先在电脑上测试一下，能获取到IPV6地址就行。不行就试试[其他的地址](https://blog.csdn.net/longzhizhui926/article/details/83002685)。

![command-test](./images/command-test.png)

提交。

[检查域名解析情况](https://zijian.aliyun.com/)。

