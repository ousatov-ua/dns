# ⚡Filtering Caching DNS Resolver⚡

<div align="center">

![dns](https://img.shields.io/badge/-dns-D8BFD8?logo=unrealengine&logoColor=3a3a3d)
&nbsp;&nbsp;[![release](https://img.shields.io/github/v/release/ousatov-ua/dns?display_name=release&logo=rstudio&color=90EE90&logoColor=8FBC8F)](https://github.com/ousatov-ua/dns/releases/latest/)
&nbsp;&nbsp;![visitors](https://img.shields.io/endpoint?color=4883c2&label=visitors&logo=github&url=https%3A%2F%2Fhits.dwyl.com%2Fousatov-ua%2Fdns.json)
&nbsp;&nbsp;![license](https://img.shields.io/github/license/ousatov-ua/dns?color=CED8E1)
&nbsp;&nbsp;![GitHub last commit](https://img.shields.io/github/last-commit/ousatov-ua/dns)

</div>

🔸 Current HOWTO is for Debian based distributions, tested on Debian 12.

> [!TIP]
> For Home network I would say that minimal requirements are 1 CPU core + 2 Gb RAM.
> 
> Having 2 CPU cores and 4Gb RAM will is more than compfortable.

🔸 Should work on other distributions with minimal changes

🔸 I'm working on a script to automate next steps.


> [!IMPORTANT]
> 🎉 Many thanks to: [AA ar51an](https://github.com/ar51an), [Gerd hagezy](https://github.com/hagezi). Please give a star for their awesome work! 🎉

## 🧰 General configuration
<details>
<summary><i>expand</i> 👉</summary>

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
  sudo ufw allow from <ip> proto tcp to any port 53/udp
  ```
* Apply rules:

  ```sh
  sudo ufw reload
  ```
</details>

## 🧰 Unbound
<details>
<summary><i>expand</i> 👉</summary>

#### 🔸 Install Unbound

* We need to compile it locally because default `Unbound` from `apt` does not include `cachedb` module.

```shell
wget https://github.com/NLnetLabs/unbound/archive/refs/tags/release-1.19.3.zip
unzip release-1.19.3.zip
cd release-1.19.3
sudo apt install bison flex libevent-dev libexpat1-dev libhiredis-dev libnghttp2-dev libprotobuf-c-dev libssl-dev libsystemd-dev protobuf-c-compiler python3-dev swig
```
* Compilation flags (I used next but you are free to specify any you want)
```shell
export CFLAGS="-Ofast -ffloat-store -ffast-math -fno-rounding-math -fno-signaling-nans -fcx-limited-range -fno-math-errno -funsafe-math-optimizations -fassociative-math -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math -frounding-math -fsingle-precision-constant -fcx-fortran-rules -flto"
```

> [!IMPORTANT]
> Maybe I'm doing something wrong with CFLAGS, but Makefile produced does not contain passed options via `export`.
> I did next to give options: edited `Makefile` generated and put gcc flags to `CFLAGS=...` defined there.

* Configure, compile and install

```shell
sudo ./configure --prefix=/usr --includedir=\${prefix}/include --infodir=\${prefix}/share/info --mandir=\${prefix}/share/man --localstatedir=/var --runstatedir=/run --sysconfdir=/etc --with-chroot-dir= --with-dnstap-socket-path=/run/dnstap.sock --with-libevent --with-libhiredis --with-libnghttp2 --with-pidfile=/run/unbound.pid --with-pythonmodule --with-pyunbound --with-rootkey-file=/var/lib/unbound/root.key --disable-dependency-tracking --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath --disable-silent-rules --enable-cachedb --enable-dnstap --enable-subnet --enable-systemd --enable-tfo-client --enable-tfo-server
sudo make
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
/var/unbound/run/unbound.sock rw,
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

* You can check which filters are used in `/etc/unbound/unbound.conf.d/server.conf` and `/opt/unbound/update-conf.sh`

#### 🔸 Unbound service
* Put `unbound-update-config.service` and `unbound-update-config.timer` in corresponding path.

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound-update-config.timer`
```

* Put `/etc/systemd/system/unbound.service` from repo.

#### 🔸 Redis

* Install Redis

```shell
sudo apt install redis-server
```

* Put `/etc/redis/redis.conf` from repo

```shell
sudo systemctl enable --now redis-server
```

#### 🔸 Running

* Now you should be able to run Unbound

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound.service
```
</details>

## 🧰 Dnsdist
<details>
<summary><i>expand</i> 👉</summary>

* Dnsdist is used as facade for Unbound: to give DoH/DoH3/DoT/DoQ

* Follow instructions for installing Dnsdist from their official site.

* Put `/etc/dnsdist/dnsdist.conf` from repo.
* Put crt and pem to `/opt/lego` (edit `dnsdist.conf` to point to right direction and certificate/key filenames)
* Generate key to access dnsdist's console:

```shell
sudo dnsdist
>makeKey()
```
Copy key to dnsdist.conf as

```shell
setKey("<key from console>")
```
* Generate password for webServerConfig

```shell
>hashPassword("<your password>")
```

Put it to config

* Start dnsdist

```shell
sudo systemtl enable --now dnsdist.service
```

</details>

## 🧰 Monitoring
<details>
<summary><i>expand</i> 👉</summary>


🔸 Follow next HOWTO

[unbound-dashboard](https://github.com/ar51an/unbound-dashboard) or forked one [unbound-dashboard-forked](https://github.com/ousatov-ua/unbound-dashboard)

[unbound-exporter](https://github.com/ar51an/unbound-exporter) or forked one [unbound-exporter-forked](https://github.com/ousatov-ua/unbound-exporter)

</details>



***Thanks for your support!***
