---
title: CAWithSSL
date: 2025-07-09 21:09:14
tags:
---

# CA与SSL证书

CA(Certificate Authority)证书颁发机构,是一家公司或组织,负责验证实体(网站,电子邮件地址,公司或个人)的身份,并签发**数字证书**将其与加密密钥绑定

> 数字证书(Digital Certificate)是一个电子文件,提供:
>
> - 认证,作为验证其所颁发实体身份的凭证
> - 加密,用于在互联网等不安全网络上进行安全通信
> - 使用该证书签署的文件具有完整性,确保其在传输过程中不会被第三方篡改

这些证书通过**公钥加密技术**使双方能够进行安全,加密的通信.

证书颁发机构(CA)核实证书申请者的身份,并颁发包含其公钥的证书.随后CA会使用自己的私钥对颁发的证书进行数字签名,以此确立对证书有效性的信任.

CA证书是CA机构签发的数字证书,相当于CA机构的"身份证"

SSL证书是CA机构签发的数字证书,用于验证服务器的身份

HTTPS 相比 HTTP最大的不同就是多了一层 SSL (Secure Sockets Layer 安全套接层)或 TLS (Transport Layer Security 安全传输层协议)。有了这个安全层，就确保了互联网上通信双方的通信安全。

## TLS的传输过程

TLS(Transport Layer Security)传输层安全性协议,最终目标是建立一个临时的,对称的会话密钥.**非对称加密**用于安全地交换或协商这个临时的**对称密钥**.

> 非对称加密:使用一对数学上关联的密钥:公钥和私钥
>
> 公钥加密的数据只有对应的私钥可以解密,私钥加密的数据可以用公钥解密,通过私钥计算出公钥比较容易,但通过公钥计算出私钥却极难.
>
> 公钥可以在网络上传播(这也意味着它已经被泄露),而私钥必须严格保密,不能泄露
>
> 对称加密:加密和解密使用同一密钥,最终使用对称密钥是因为加密速度快,适合加密大量数据.

在TLS开始之前服务器持有自己的**非对称密钥对**`Server_Public_Key`和`Server_Private_Key`

### 建立TCP连接

客户端发起一个到服务器指定端口(通常是HTTPS的443端口)的TCP连接

服务器接受连接请求,TCP三次握手完成后,可靠的传输通道建立

### TLS握手

通过TLS建立安全的通道

#### Client Hello

客户端想要安全地连接到服务器,首先客户端向服务器发送`ClientHello`消息,内容包括:

- 支持的TLS协议版本
- 客户端生成的随机数`Client_Random`
- 支持的密码套件列表,此套件指明了后续使用的算法组合,例如`TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`:
  - 密钥交换算法:`ECDHE`
  - 认证算法:`RSA`
  - 对称加密算法:`AES_256_GCM`
  - 消息认证码算法(MAC):`SHA384`
- 支持的扩展,例如支持的椭圆曲线列表,签名算法列表等

#### Server Hello

服务端响应客户端,包含:

- 选择的TLS协议版本
- 服务器生成随机数`Server_Random`
- 从客户端列表中选择的密码套件
- 可能选择的会话ID(用于会话恢复)

服务器会将服务器证书链(Server Certificate Chain),其数字证书以及构建完整信任链所需的任何中间CA证书发送给客户端:

- 服务器证书:
  - 服务器的域名
  - 服务器的公钥
  - 签发该证书的CA信息
  - 有效期
  - 签发该证书的CA的私钥生成的数字签名
- 中间CA证书

> 大多数CA处于安全和管理的原因使用中间CA来签发终端实体证书(服务器证书)
>
> 服务器需要提供从服务器证书回溯到客户端信任的根CA所需的所有中间证书(通常不包括根CA证书本身,因为客户端应该预装)

#### Server CertificateVerify(可选)

在TLS1.3中,服务器发送此消息证明它拥有与证书中公钥对应的私钥

服务器使用其私钥对之前握手消息的哈希值进行签名并发送,客户端可以用服务器证书中的公钥验证此签名

#### Server Hello Done(可选)

在TLS1.2及更早版本中常见,表示服务器Hello阶段结束.TLS1.3流程更紧凑,通常省略

#### 客户端证书验证

Client Certificate Verification

客户端收到服务器证书链后,开始进行严格的验证:

1. 信任锚检查:客户端在其**信任存储(Trust Store)**中查找服务器证书链顶端的根CA证书,如果找不到信任的根CA,验证失败.

   > 信任存储:操作系统或浏览器内置的受信任根CA证书列表

2. 证书链验证:

   1. 客户端使用信任的根CA的公钥(从信任存储中获得)来验证第一个中间CA证书上的签名(如果没有的话则直接验证服务器证书)
   2. 如果签名有效,客户端信任这个中间CA,然后使用这个已验证的中间CA的公钥(从刚收到的中间证书中获得)来验证下一个中间证书(或者最终的服务器证书)上的签名
   3. 这个过程逐级向下验证,直到验证了服务器证书本身的签名

3. 域名检验:检查服务器证书中的SAN或CN字段是否包含客户端正在连接的域名(由SNI或URL指定),如果不匹配,验证失败

4. 有效期验证:检查服务器证书的`Valid From`和`Valid To`日期,确保证书当前有效且未过期

5. 吊销状态检查(可选):客户端检查服务器证书是否已被CA撤销,通常通过下面两种方式之一:

   - 证书吊销列表(CRL)
   - 在线证书状态协议(OCSP)

6. 密钥用途/扩展密钥用途:检查证书是否被授权用于服务器身份验证(`serverAuth`)

如果以上任何一步验证失败,客户端将终止连接,并向用户显示严重的安全警告

#### 客户端密钥交换与计算主密钥

- 如果使用Diffie-Hellman(椭圆曲线)类密钥交换:
  客户端生成一个预主密钥(Pre-Master Secret)并使用服务器证书中提供的服务器公钥对其进行加密,然后将加密结果哦发送给服务器.

- 在TLS1.3中密钥交换通常集成在Client Hello和Server Hello的扩展中,使用更高效的椭圆曲线Diffie-Hellman(ECDHE),实际上发送的是客户端的临时公钥

现在客户端和服务器都拥有:

1. 客户端随机数Client_Random
2. 服务器随机数Server_Random
3. 预主密钥Pre-Master Secret

然后双方使用协商好的伪随机函数(PRF,由密码套件决定)和这三个输入,独立计算出相同的主密钥(Master Secret),这是一个对称密钥

#### 客户端握手完成

客户端计算到目前为止所有握手消息的哈希值(称为`verify_data`),使用刚刚生成的主密钥派生出的密钥对其进行加密(或者计算消息验证码MAC),然后发送给服务器,在TLS1.3中,这是第一条加密的消息,是握手阶段的加密起点.

这个 `Finished` 消息让服务器确认:客户端拥有正确的密钥,并且握手消息在传输过程中没有被篡改

> TLS1.2及更早会在Finished消息前有客户端切换密码规范 (Change Cipher Spec)消息

#### 服务器握手完成

服务器同样计算出到目前为止所有握手消息的哈希值,使用主密钥派生的密钥进行加密(或计算MAC),然后发送给客户端

客户端验证此消息,同样确认:服务器拥有正确的密钥,并且握手消息在传输过程中没有被篡改

> TLS1.2及更早在此Finished消息前同样有服务器切换密码规范 (Change Cipher Spec)消息

**至此建立了安全的数据传输通道**

#### 对称加密通信

客户端和服务器都使用从主密钥派生出的相同的会话密钥(Session Keys)(通常包括对称加密密钥如AES密钥和消息认证码MAC密钥)

所有后续的应用层记录(例如HTTP请求和响应)都被分割成TLS记录(TLS Records)

每个TLS记录使用协商好的对称加密算法(如AES-GCM)进行加密

同时使用协商好的MAC算法对记录计算消息验证码(MAC),确保数据的完整性和真实性

加密并认证后的记录通过网络发送,接收方解密记录并验证MAC,确保数据来自合法对段且未被篡改后,将数据传递给上层应用(如HTTP服务器/浏览器)

#### 关闭通知

当任何一方决定关闭连接时，会发送一个加密的 `close_notify` 警报消息。这是优雅关闭，通知对端连接即将终止。
在收到 `close_notify` 后，另一方也应回复自己的 `close_notify`（尽管TCP FIN可能更快到达）。
最后，关闭底层的TCP连接。

## 为什么需要CA机构

## 申请SSL证书

### 发起CSR请求

CA工作流程的第一步是申请者发起CSR(证书签名请求)申请SSL证书

CSR需要包含以下内容:

- 申请者的公钥(Public Key)
- 申请的域名
- 组织信息(名称,地址等)
- 数字签名(由申请者的私钥生成)

> CSR中的数字签名,是先对其余内容计算哈希值,然后使用私钥加密后得到的,附在其他内容末尾

CA收到CSR请求后,会首先取出申请者的公钥,然后解密数字签名,得到原哈希值,然后重新计算CSR内容(除数字签名以外的内容)的哈希值,对比两个哈希值,如果一致则证明CSR未被篡改



## 创建自己的CA并签发SSL证书

### 为CA创建私钥

```
openssl genrsa -aes256 -out myrootCA.key 4096
# 输入密码
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

### 创建CA证书

```
# 1826天为5年
openssl req -x509 -new -nodes -key myrootCA.key -sha256 -days 1826 -out myrootCA.crt
Enter pass phrase for myrootCA.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:AT
State or Province Name (full name) [Some-State]:Vienna
Locality Name (eg, city) []:Vienna
Organization Name (eg, company) [Internet Widgits Pty Ltd]:MyOrg
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:My Root CA
Email Address []:test123@123.com

# 也可以使用下面的命令直接创建
openssl req -x509 -new -nodes -key myrootCA.key -sha256 -days 1826 -out myrootCA.crt -subj '/CN=My Root CA/C=AT/ST=Vienna/L=Vienna/O=MyOrg'
```

### 将CA证书添加到受信任的根证书

```
sudo apt install -y ca-certificates
sudo cp myrootCA.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

### 为网络服务器创建SSL证书

```
MYCERT=myserver
openssl req -new -nodes -out $MYCERT.csr -newkey rsa:4096 -keyout $MYCERT.key -subj '/CN=www.nginx.com/C=CN/ST=Beijing/L=Beijing/O=My Nginx Server'

# 为SAN属性创建v3扩展文件
cat > $MYCERT.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment,
dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = www.nginx.com
DNS.2 = nginx.com
IP.1 = 127.0.0.1
EOF
```

> v3.ext文件包含了证书v3扩展的属性。这特别包括SAN（主题备用名称），其中含有DNS或IP的信息，浏览器需要这些信息来信任证书（你需要以某种方式确保mysite.local使用的是为mysite.local颁发的证书）。

### 签署证书

```
openssl x509 -req -in $MYCERT.csr -CA $CANAME.crt -CAkey $CANAME.key -CAcreateserial -out $MYCERT.crt -days 730 -sha256 -extfile $MYCERT.v3.ext
```

验证证书是否包含IP

```
openssl x509 -in myserver.crt -text -noout | grep -A1 "Subject Alternative Name"
```

### 部署证书

```
sudo cp myserver.crt /etc/nginx/ssl/nginx_cert.crt
sudo cp myserver.key /etc/nginx/ssl/nginx_cert.key
cd /etc/nginx/ssl/
ll
total 16
drwxr-xr-x 2 root root 4096 Jul  9 16:48 ./
drwxr-xr-x 9 root root 4096 Jul  9 16:47 ../
-rw-r--r-- 1 root root 2069 Jul  9 16:48 nginx_cert.crt
-rw------- 1 root root 3272 Jul  9 16:48 nginx_cert.key
sudo chown root:www-data nginx_cert.key 
sudo chmod 640 nginx_cert.key 
sudo chown root:root nginx_cert.crt 
sudo chmod 644 nginx_cert.crt 
ll
total 16
drwxr-xr-x 2 root root     4096 Jul  9 16:48 ./
drwxr-xr-x 9 root root     4096 Jul  9 16:47 ../
-rw-r--r-- 1 root root     2069 Jul  9 16:48 nginx_cert.crt
-rw-r----- 1 root www-data 3272 Jul  9 16:48 nginx_cert.key
```

nginx配置

```
server {
        # SSL configuration
        #
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        ssl_certificate /etc/nginx/ssl/nginx_cert.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx_cert.key;
}
```

结果:

```
curl https://www.nginx.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## 参考

https://segmentfault.com/a/1190000021559557
