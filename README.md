# dns
Configuration of filtering caching DNS resolver

Current HOWTO is for Debian based distributives, tests on Debian 12.

## General configuration

* Put content of `/etc/security/limits.conf` into your `limits.conf`

* Put content of `etc/sysctl.conf` into your `sysctl.conf`

#
#### > Turn off IPv6

* Edit `etc/default/grub`, make sure that `ipv6.disable=1` is present, e.g.:

  ```sh
  GRUB_CMDLINE_LINUX="ipv6.disable=1"
  ```

* Run:
  
  ```sh
  sudo update-grub
  ```

* Reboot

#
#### > Hyper-threading

* If you want HT disabled but you cannot disable it in BIOS, make sure that `nosmt` is present, e.g.:
  
  ```sh
  GRUB_CMDLINE_LINUX="nosmt"
  ```
  Apply it:
  
  ```sh
  sudo update-grub
  ```
#
#### > !!!Optionally!!! Tuned package

* Use `tuned` package for network latency optimizations:
  
  ```shell
  sudo apt install tuned
  sudo tuned-adm profile network-latency
  sudo reboot
  ```
#
#### > UFW

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

* If to some specific IP address only:
  
  ```shell
  sudo ufw allow from <ip> proto tcp to any port 53/udp
  ```
  Apply rules:

  ```sh
  sudo ufw reload
  ```

## Unbound

There are two ways: to use package for your distributive (e.g. `apt` for Debian) or build it locally.

#
#### > Build locally

```shell

wget https://github.com/NLnetLabs/unbound/archive/refs/tags/release-1.19.3.zip
unzip release-1.19.3.zip
cd release-1.19.3
sudo apt install bison flex libevent-dev libexpat1-dev libhiredis-dev libnghttp2-dev libprotobuf-c-dev libssl-dev libsystemd-dev protobuf-c-compiler python3-dev swig
export CFLAGS="-O2"
sudo ./configure --prefix=/usr --includedir=\${prefix}/include --infodir=\${prefix}/share/info --mandir=\${prefix}/share/man --localstatedir=/var --runstatedir=/run --sysconfdir=/etc --with-chroot-dir= --with-dnstap-socket-path=/run/dnstap.sock --with-libevent --with-libhiredis --with-libnghttp2 --with-pidfile=/run/unbound.pid --with-pythonmodule --with-pyunbound --with-rootkey-file=/var/lib/unbound/root.key --disable-dependency-tracking --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath --disable-silent-rules --enable-cachedb --enable-dnstap --enable-subnet --enable-systemd --enable-tfo-client --enable-tfo-server
sudo make
sudo make install
```

* Unbound and chroot 

Unbound is running under chroot.

Next steps should be done for sure if Unbound is running under chroot, otherwise it will fail to create *.sock and log files.

```shell
sudo vim /etc/apparmor.d/local/usr.sbin.unbound
```

Put next to this file

```shell
/var/log/unbound/unbound.log rw,
/var/unbound/run/unbound.sock rw,
```

Apply it
```shell
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.unbound
```

* Create logging staff

```shell
sudo mkdir /var/log/unbound
sudo chown unbound:unbound /var/log/unbound
```

* Replace default configuration of Unbound with files from `/etc/unbound`.

* Setup unbound-control:

```shell
sudo unbound-control-setup
```

* Setup root.hints and root.key

```shell
sudo apt install dns-root-data
sudo ln -s /usr/share/dns/root.key /var/lib/unbound/root.key
sudo ln -s /usr/share/dns/root.hints /var/lib/unbound/root.hints
```
* For DNS filtering put `update-conf.sh` into corresponding path

```shell
sudo chmod +x /opt/unbound/update-conf.sh
sudo mkdir /etc/unbound/rules
sudo sh /opt/unbound/update-conf.sh
```

* Put `unbound-update-config.service` and `unbound-update-config.timer` in corresponding path.

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound-update-config.timer`
```
* Create service

Put `/etc/systemd/system/unbound.service` from repo.

* Install Redis

```shell
sudo apt install redis-server
```

Put `/etc/redis/redis.conf` from repo

```shell
sudo systemctl enable --now redis-server
```

Now you should be able to run Unbound

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now unbound.service
```

## Dnsdist

Dnsdist is used as facade for Unbound: to give DoH/DoH3/DoT/DoQ

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

## Monitoring

> [!IMPORTANT]
> Many thanks to [AA ar51an](https://github.com/ar51an) for his work

Please use https://github.com/ar51an/unbound-dashboard or forked one https://github.com/ousatov-ua/unbound-dashboard

and https://github.com/ar51an/unbound-exporter or forked one https://github.com/ousatov-ua/unbound-exporter
