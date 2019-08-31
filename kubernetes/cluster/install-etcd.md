## 安装kubernetes集群准备之---etcd集群

ETCD节点：

- `192.168.6.238`
- `192.168.6.239`
- `192.168.6.240`



### 生成证书

- 工作目录：

  ```bash
  mkdir -p ~/kubernetes/etcd/etcd_tls
  cd ~/kubernetes/etcd/etcd_tls
  ```

- 下载工具

  ```bash
  # 下载
  wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
  
  # 添加执行权限
  chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
  
  # 移动文件
  mv ./cfssl_linux-amd64 /usr/local/bin/cfssl
  mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
  ```

- 编写配置文件

  - `etcd-root-ca-csr.json`

    ```json
    {
        "CN": "kubernetes",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "BeiJing",
                "ST": "BeiJing",
                "O": "k8s",
                "OU": "System"
            }
        ]
    }
    ```

  - `config.json`

    ```json
    {
    "signing": {
        "default": {
          "expiry": "87600h"
          },
        "profiles": {
          "kubernetes": {
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ],
            "expiry": "87600h"
          }
        }
    }
    }
    ```

  - `etcd-csr.json`

    ```json
    {
      "CN": "etcd",
      "hosts": [
        "127.0.0.1",
        "192.168.6.238",
        "192.168.6.239",
        "192.168.6.240"
      ],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "ST": "BeiJing",
          "L": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }
    ```

- **生成证书：**

  - `cfssl gencert --initca=true etcd-root-ca-csr.json | cfssljson --bare etcd-root-ca`

    ```
    root@ubuntu238:~/kubernetes/etcd_tls# cfssl gencert --initca=true etcd-root-ca-2019/08/29 03:56:30 [INFO] generating a new CA key and certificate from CSR
    2019/08/29 03:56:30 [INFO] generate received request
    2019/08/29 03:56:30 [INFO] received CSR
    2019/08/29 03:56:30 [INFO] generating key: rsa-2048
    2019/08/29 03:56:30 [INFO] encoded CSR
    2019/08/29 03:56:30 [INFO] signed certificate with serial number 166623407831683885732729802723806887637226945669
    ```

  - `cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd`

    ```
    root@ubuntu238:~/kubernetes/etcd_tls# cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
    2019/08/29 03:56:30 [INFO] generate received request
    2019/08/29 03:56:30 [INFO] received CSR
    2019/08/29 03:56:30 [INFO] generating key: rsa-2048
    2019/08/29 03:56:31 [INFO] encoded CSR
    2019/08/29 03:56:31 [INFO] signed certificate with serial number 310889394797062107238201817384398517316221695839
    2019/08/29 03:56:31 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    ```

  - 移动文件到：`./ssl`

    ```bash
    # 把etcd-root-ca.pem重命名为ca.pem
    mv etcd.pem etcd-key.pem ./ssl
    mv etcd-root-ca.pem ./ssl/ca.pem
    ```

  - 查看文件：

    ```bash
    root@ubuntu238:~/kubernetes/etcd/etcd_tls# tree
    .
    ├── config.json
    ├── etcd.csr
    ├── etcd-csr.json
    ├── etcd-root-ca.csr
    ├── etcd-root-ca-csr.json
    ├── etcd-root-ca-key.pem
    ├── generate-cert.sh
    ├── install-tools.sh
    └── ssl
        ├── ca.pem
        ├── etcd-key.pem
        └── etcd.pem
    
    1 directory, 11 files
    ```

  - 查看证书

    ```bash
    root@ubuntu238:~/kubernetes/etcd_tls# openssl x509 -in ./ssl/etcd.pem -noout -text | grep ' Not '
                Not Before: Aug 29 07:52:00 2019 GMT
                Not After : Aug 26 07:52:00 2029 GMT
    ```

- 相关脚本：

  - 安装创建证书的工具：`install-tools.sh`

    ```bash
    #!/bin/bash
    # 下载
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
    
    # 添加执行权限
    chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
    
    # 移动文件
    mv ./cfssl_linux-amd64 /usr/local/bin/cfssl
    mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
    mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
    ```

  - 生成证书和移动到：ssl目录

    ```bash
    #!/bin/bash
    
    # 生成证书
    cfssl gencert --initca=true etcd-root-ca-csr.json | cfssljson --bare etcd-root-ca
    
    cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
    
    # 移动证书到./ssl
    mkdir ./ssl
    
    # 把etcd-root-ca.pem重命名为ca.pem
    mv etcd.pem etcd-key.pem ./ssl
    mv etcd-root-ca.pem ./ssl/ca.pem
    
    # 查看证书
    openssl x509 -in ./ssl/etcd.pem -noout -text | grep ' Not '
    ```

- 同步证书到其它节点

  ```bash
  root@ubuntu238:~/kubernetes/etcd# rsync -r /etc/etcd/   root@192.168.6.239:/etc/etcd/
  root@ubuntu238:~/kubernetes/etcd# rsync -r /etc/etcd/   root@192.168.6.240:/etc/etcd/
  ```



### 安装etcd

- 参考文档：`https://github.com/etcd-io/etcd/releases`

  ```bash
  #!/bin/bash
  ETCD_VER=v3.4.0-rc.3
  
  # choose either URL
  GOOGLE_URL=https://storage.googleapis.com/etcd
  GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
  DOWNLOAD_URL=${GITHUB_URL}
  
  rm -f ./download/etcd-${ETCD_VER}-linux-amd64.tar.gz
  rm -rf ./download/etcd && mkdir -p ./download/etcd
  
  echo ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
  curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o ./download/etcd-${ETCD_VER}-linux-amd64.tar.gz
  tar xzvf ./download/etcd-${ETCD_VER}-linux-amd64.tar.gz -C ./download/etcd --strip-components=1
  rm -f ./download/etcd-${ETCD_VER}-linux-amd64.tar.gz
  
  ./download/etcd/etcd --version
  ./download/etcd/etcdctl version
  
  # 移动到PATH路径
  mv ./download/etcd/etcd* /usr/local/bin/
  
  # 删掉download目录
  rm -rf ./download/
  ```



### 启动etcd

现在已经准备好了：

- 证书：`/etc/etcd/ssl`
- 安装好了etcd：`/usr/local/bin/etcd`

- 生成etcd.service的脚本: `/root/kubernetes/etcd/generate_etcd_service.sh`

  ```bash
  #!/bin/bash
  
  export NODE_NAME=NODE238
  export NODE_IP=192.168.6.238
  export NODE_IPS="192.168.6.238 192.168.6.239 192.168.6.240"
  
  # etcd集群通信的IP和端口
  export ETCD_NODES="NODE238"=https://192.168.6.238:2380,"NODE239"=https://192.168.6.239:2380,"NODE240"=https://192.168.6.240:2380
  
  # 创建目录
  mkdir /var/lib/etcd/
  
  cat > etcd.service <<EOF
  [Unit]
  Description=Etcd Server
  After=network.target
  After=network-online.target
  Wants=network-online.target
  Documentation=https://github.com/coreos
  
  [Service]
  Type=notify
  WorkingDirectory=/var/lib/etcd/
  ExecStart=/usr/local/bin/etcd \\
    --name=${NODE_NAME} \\
    --cert-file=/etc/etcd/ssl/etcd.pem \\
    --key-file=/etc/etcd/ssl/etcd-key.pem \\
    --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
    --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
    --trusted-ca-file=/etc/etcd/ssl/ca.pem \\
    --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \\
    --initial-advertise-peer-urls=https://${NODE_IP}:2380 \\
    --listen-peer-urls=https://${NODE_IP}:2380 \\
    --listen-client-urls=https://${NODE_IP}:2379,http://127.0.0.1:2379 \\
    --advertise-client-urls=https://${NODE_IP}:2379 \\
    --initial-cluster-token=etcd-cluster-0 \\
    --initial-cluster=${ETCD_NODES} \\
    --initial-cluster-state=new \\
    --data-dir=/var/lib/etcd
  Restart=on-failure
  RestartSec=5
  LimitNOFILE=65536
  
  [Install]
  WantedBy=multi-user.target
  EOF
  
  # 记得修改上面的环境变量
  mv etcd.service /etc/systemd/system/
  
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
  systemctl status etcd
  ```

- 执行这个脚本：`bash generate_etcd_service.sh`



### 其它机器安装

- 同步脚本去其它服务器

  ```bash
  rsync -r /root/kubernetes/ root@192.168.6.239:/root/kubernetes/
  rsync -r /root/kubernetes/ root@192.168.6.240:/root/kubernetes/
  ```

- 执行安装etcd的脚本：

  ```bash
  bash /root/kubernetes/etcd/install-etcd.sh
  ```

- 修改生成etcd.service的文件: `/root/kubernetes/etcd/generate_etcd_service.sh`

  ```
  # 修改下面的值为自己节点的
  export NODE_NAME=NODE238
  export NODE_IP=192.168.6.238
  ```

- 执行生成etcd的service的文件和启动

  ```bash
  bash /root/kubernetes/etcd/generate_etcd_service.sh
  ```

### 验证etcd服务

- 执行etcdctl

  ```bash
  etcdctl  \
  --endpoints=https://192.168.6.238:2379,https://192.168.6.239:2379, \
  https://192.168.6.240:2379  \
  --cacert=/etc/etcd/ssl/ca.pem   --cert=/etc/etcd/ssl/etcd.pem  \
  --key=/etc/etcd/ssl/etcd-key.pem endpoint health
  ```

  输出结果:

  ```
  https://192.168.6.240:2379 is healthy: successfully committed proposal: took = 12.779322ms
  https://192.168.6.238:2379 is healthy: successfully committed proposal: took = 13.265907ms
  https://192.168.6.239:2379 is healthy: successfully committed proposal: took = 13.336592ms
  ```

