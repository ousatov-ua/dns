# ⚡Filtering Caching DNS Resolver⚡

<div align="center">

![dns](https://img.shields.io/badge/-dns-D8BFD8?logo=unrealengine&logoColor=3a3a3d)
&nbsp;&nbsp;[![release](https://img.shields.io/github/v/release/ousatov-ua/dns?display_name=release&logo=rstudio&color=90EE90&logoColor=8FBC8F)](https://github.com/ousatov-ua/dns/releases/latest/)
&nbsp;&nbsp;![visitors](https://img.shields.io/endpoint?color=4883c2&label=visitors&logo=github&url=https%3A%2F%2Fhits.dwyl.com%2Fousatov-ua%2Fdns.json)
&nbsp;&nbsp;![license](https://img.shields.io/github/license/ousatov-ua/dns?color=CED8E1)
&nbsp;&nbsp;![GitHub last commit](https://img.shields.io/github/last-commit/ousatov-ua/dns)

</div>

🔸 Intro

* Current HOWTO defines steps to setup caching DNS resolver with configuration for family usage.

* It gives possibility to have next DNS endpoints: Plain/DoH/DoH3/DoQ/DoT.

* Facade for DNS interfaces is [Dnsdist](https://dnsdist.org/).

* Main DNS resolver is [Unbound](https://nlnetlabs.nl/projects/unbound/about/). It works as **resolver**, without forwarding queries to any upstream DNS servers.

* Second level cache is [Redis](https://redis.io/) - for [Unbound](https://nlnetlabs.nl/projects/unbound/about/) only

* There are also BIND9 and PDNS-recursor setup instructions as alternative.

* Everything is prepared to setup monitoring tools such as `Loki`, `Prometheus`, `Promtail` and `Grafana`

🔸 Tested on Debian 12.

🔸 Should work on other distributions with minimal changes

🔸 I'm working on a script to automate next steps.

> [!IMPORTANT]
> 🎉 Many thanks to: [AA ar51an](https://github.com/ar51an), [Gerd hagezy](https://github.com/hagezi). Please give a star for their awesome work! 🎉


> [!TIP]
> For Home network I would say that minimal requirements are 1 CPU core and 2 Gb RAM.
> 
> Having 2 CPU cores and 4Gb RAM is more than compfortable.
>
> Regarding hyper-threading: In my testings I found out that disabling HT gives better performance results. Your observations can vary.

## 🧰 General configuration
<details>
<summary><i>expand</i></summary>

#### 🔸 !!!Optional!!! IPv6 (just for FAQ)

* Edit `/etc/default/grub`, make sure that `ipv6.disable=1` is present, e.g.:

  ```sh
  GRUB_CMDLINE_LINUX="ipv6.disable=1"
  ```
* Run:

  ```sh
  sudo update-grub
  ```
* Reboot

#### 🔸 Limits and Sysctl

* Next steps are for optimizing/securing current environment. 

* Put content of `/etc/security/limits.conf` into your `limits.conf`

* Put content of `etc/sysctl.conf` into your `sysctl.conf`


#### 🔸 !!!Optional!!! Hyper-threading

* If you want HT disabled but you cannot disable it in BIOS, make sure that `nosmt` is present in `/etc/default/grub`, e.g.:
  
  ```sh
  GRUB_CMDLINE_LINUX="nosmt"
  ```
* Apply it:
  
  ```sh
  sudo update-grub
  ```

#### 🔸 !!!Optional!!! Tuned package

* Use `tuned` package for network latency optimizations:
  
  ```shell
  sudo apt install tuned
  sudo tuned-adm profile network-latency
  sudo reboot
  ```
#### 🔸 UFW

* Review current configuration of UFW:
  
  ```sh
  sudo ufw status
  ```

* To delete some particular rule run:
  
  ```shell
  sudo ufw status numbered
  sudo ufw delete <number>
  ```
* Verify that UFW has these configuration:
  
  ```shell
  sudo ufw allow 443
  sudo ufw limit 22/tcp
  ```

* If you want port `53` accessible to all:
  
  ```shell
  sudo ufw allow 53/udp
  ```

* For a specific IP address only:
  
  ```shell
  sudo ufw allow from <ip> proto udp to any port 53
  ```
* Apply rules:

  ```sh
  sudo ufw reload
  ```
#### 🔸 Compiler

* Setup steps for `Unbound` and `Dnsdist` contain possibility to compile services locally. This means that you'll need compiler :) In next sections it is supposed using standard compiler for your distributives.
* You can consider to use [AOCC](https://www.amd.com/en/developer/aocc.html) compiler if your processor is AMD. Many sources declare that code compiled by `AOCC` is faster on AMD. All you need is to follow instructions for `AOCC`.

#### 🔸 Useful things
* If you need to create some direcotory on startup, for instance on this path `/var/run/some-dir` and setup rights for `user:user-group` then create next file

```shell
vim /etc/tmpfiles.d/some-service.conf
```
* Put this content:

```shell
﻿d /var/run/some-dir 0755 user user-group
```
  
</details>

## 🧰 Unbound
<details>
<summary><i>expand</i></summary>

#### 🔸 Install Unbound

* We need to compile it locally because default `Unbound` from `apt` does not include `cachedb` module.
* Even if you will not use `Redis` as Level 2 cache for `Unbound` I would anyway suggest to compile `Unbound` locally to have the latest version. 

```shell
wget https://github.com/NLnetLabs/unbound/archive/refs/tags/release-1.19.3.zip
unzip release-1.19.3.zip
cd release-1.19.3
sudo apt install bison flex libevent-dev libexpat1-dev libhiredis-dev libnghttp2-dev libprotobuf-c-dev libssl-dev libsystemd-dev protobuf-c-compiler python3-dev swig
```
* Compilation flags (I used next but you are free to specify any you want)
```shell
export CFLAGS="-Ofast -pipe -march=native"
export CXXFLAGS="-Ofast -pipe -march=native"
export CPPFLAGS="-Ofast -pipe -march=native"
```

* Configure

```shell
./configure --prefix=/usr --includedir=\${prefix}/include --infodir=\${prefix}/share/info --mandir=\${prefix}/share/man --localstatedir=/var --runstatedir=/run --sysconfdir=/etc --with-chroot-dir= --with-dnstap-socket-path=/run/dnstap.sock --with-libevent --with-libhiredis --with-libnghttp2 --with-pidfile=/run/unbound.pid --with-pythonmodule --with-pyunbound --with-rootkey-file=/var/lib/unbound/root.key --disable-dependency-tracking --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath --disable-silent-rules --enable-cachedb --enable-dnstap --enable-subnet --enable-systemd --enable-tfo-client --enable-tfo-server --without-pthreads --without-solaris-threads
```

* Make and install

```shell
make
sudo make install
```

#### 🔸 Unbound and chroot 

* Unbound usually is running under chroot.

* Next steps usually are needed if Unbound is running under chroot, otherwise it will fail to create `*.sock` and `*.log` files.

```shell
sudo vim /etc/apparmor.d/local/usr.sbin.unbound
```

* Put next to this file

```shell
/var/log/unbound/unbound.log rw,
/run/unbound.sock rw,
```

* Apply it
```shell
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.unbound
```

#### 🔸 Create logging staff

```shell
sudo mkdir /var/log/unbound
sudo chown unbound:unbound /var/log/unbound
```
* Put file `/etc/logrotate.d/unbound` to `/etc/logrotate.d/`

#### 🔸 Unbound config

* Replace default configuration of Unbound with files from `/etc/unbound`.

* Review config, make appropriate changes for number of threads etc, default is 2 threads.
* Enable ipv6 if needed.
* Setup unbound-control:

```shell
sudo unbound-control-setup
```

#### 🔸 Root hints and key
* Setup `root.hints` and `root.key`

```shell
sudo apt install dns-root-data
sudo ln -s /usr/share/dns/root.key /var/lib/unbound/root.key
sudo ln -s /usr/share/dns/root.hints /var/lib/unbound/root.hints
```

#### 🔸 Unbound filters

* For DNS filtering put `update-conf.sh` into corresponding path

```shell
sudo chmod +x /opt/unbound/update-conf.sh
sudo mkdir /etc/unbound/rules
sudo sh /opt/unbound/update-conf.sh
```

* You can check which filters are used in `/etc/unbound/unbound.conf.d/rules.conf` and `/opt/unbound/update-conf.sh`

#### 🔸 Unbound service
* Put `unbound-update-config.service` and `unbound-update-config.timer` in corresponding path.

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound-update-config.timer`
```

* Put `/etc/systemd/system/unbound.service` from repo.
</details>

## 🧰 Redis
<details>
<summary><i>expand</i></summary>

<details>
<summary><i>🔸 Compile locally</i></summary>

```shell
wget https://download.redis.io/redis-stable.tar.gz
tar -xzvf redis-stable.tar.gz
cd redis-stable
make MALLOC=jemalloc USE_SYSTEMD=yes
sudo make install
```
* Put next content into `/etc/tmpfiles.d/redis.conf`

```shell
d /var/run/redis 0755 redis redis
``` 


* Put next content into `/etc/systemd/system/redis.service`

```shell
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf --supervised systemd
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
```
* Create user `redis` with next config

```shell
redis:x:112:116::/var/lib/redis:/usr/sbin/nologin
```

* Create folder

```shell
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis
```

</details>

<details>
<summary><i>🔸 Install Redis by `apt`</i></summary>

```shell
sudo apt install redis-server
```
</details>

* Put `/etc/redis/redis.conf` from repo

```shell
sudo systemctl enable --now redis-server
```
</details>

#### 🔸 Running Unbound

* Now you should be able to run Unbound

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound.service
```

## 🧰 Dnsdist
<details>
<summary><i>expand</i></summary>

* Dnsdist is used as facade for Unbound: to give DoH/DoH3/DoT/DoQ

<details>
<summary><i>Installing using <b>apt</b></i></summary>
* Follow instructions for installing Dnsdist from their official site.
  
* Put `/etc/dnsdist/dnsdist.conf` from repo.

* `dnsdist.conf` contains DoH configuration where you can restrict access to it using custom url. Just replace `<some secret client id>` in that configurations with some unique combination.
You can specify as many such urls as you want, separating users. For Dot/DoQ there is no such configuration, but it is possible to configure if you are using wildcard certificate.

* !!!Optional!!! If you will use DoH/DoH3/DoT/DoQ put crt and pem to `/opt/lego` (edit `dnsdist.conf` to point to right directory, also certificate/key filenames)
</details>

<details>
<summary><i>Compiling locally</i></summary>

```shell
sudo apt install autoconf automake libedit-dev libsodium-dev libtool-bin \
pkg-config protobuf-compiler libnghttp2-dev libh2o-evloop-dev libluajit-5.1-dev \
libboost-all-dev libsystemd-dev libbpf-dev libclang-dev git cmake
```

* Install **Rust** using script `/opt/install-rust.sh` from repo.
* Install **Quiche** if you need DoH3/DoQ using `/opt/install-quiche.sh` from repo. Additionally I create symlink to `quiche` lib for accessibility:

```shell
sudo ln /usr/local/lib/libdnsdist-quiche.so /usr/lib/libdnsdist-quiche.so
```

* Export CFLAGS and CXXFLAGS if you want, I'm using next:

```shell
export CFLAGS="-Ofast -pipe -march=native"
export CXXFLAGS="-Ofast -pipe -march=native"
export CPPFLAGS="-Ofast -pipe -march=native"
```
* Configure, make and install:

```shell
wget https://downloads.powerdns.com/releases/dnsdist-1.9.1.tar.bz2
tar xjf dnsdist-1.9.1.tar.bz2
cd dnsdist-1.9.1
./configure --enable-dns-over-tls --enable-dns-over-https --enable-dns-over-http3 --enable-dns-over-quic --with-systemd --with-quiche
make
sudo make install
```

* Copy generated `dnsdist.service` to `/etc/systemd/system` directory
* Copy `etc/dnsdist/dnsdist.conf` to `/usr/local/etc`. Please pay attention that there are DoH/DoH3/DoQ/DoT are configured, 
so you need to modify config to point to right certificate and private key or disable those interfaces.
* Create user `dnsdist:dnsdist` and give rights to config:

```shell
sudo chown root:dnsdist /usr/local/etc/dnsdist.conf
```
* Reload services and start dnsdist

```shell
sudo systemctl daemon-reload
```
</details>

* Generate key to access dnsdist's console:

```shell
sudo dnsdist
>makeKey()
```
* Copy key to dnsdist.conf as

```shell
setKey("<key from console>")
```
* Generate password for webServerConfig

```shell
>hashPassword("<your password>")
```

* Put it to config

* Start dnsdist

```shell
sudo systemtl enable --now dnsdist.service
```

</details>

## 🧰 Monitoring
<details>
<summary><i>expand</i></summary>


🔸 Follow next HOWTO

[unbound-dashboard](https://github.com/ar51an/unbound-dashboard) or forked one [unbound-dashboard-forked](https://github.com/ousatov-ua/unbound-dashboard)

[unbound-exporter](https://github.com/ar51an/unbound-exporter) or forked one [unbound-exporter-forked](https://github.com/ousatov-ua/unbound-exporter)

</details>



***Thanks for your support!***
