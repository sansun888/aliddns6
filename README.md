# 让 aliddns 支持 ipv6

用这里的`aliddns_update.sh`替换路由器`/koolshare/scripts/`目录下的`aliddns_update.sh`

## 操作步骤

ssh进路由器，执行以下代码：
```zsh
cd /koolshare/script/
mv aliddns_update.sh aliddns_update.bak
wget https://gitee.com/tyasky/aliddns6/blob/master/aliddns_update.sh
chmod +x aliddns_update.sh
```

**注意**：原版脚本可能将`Access Key
Secret`末尾加了`&`，在路由器界面手动删除，提交。

## 补充

- [电信获取ipv6](https://m.ithome.com/html/405571.htm)
- aliddns 网页端*获取 IP*：
```
curl -s v6.ident.me
```
此行代码可以现在电脑上测试一下，能获取到IPV6地址就行。不行就试试[其他的地址](https://blog.csdn.net/longzhizhui926/article/details/83002685)
