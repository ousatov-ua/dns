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
  
  ```sh
  sudo apt install tuned
  sudo tuned-adm profile network-latency
  sudo reboot
  ```
#
#### > Configure UFW:

* Review current configuration of UFW:
  
  ```sh
  sudo ufw status
  ```

* To delete some particular rule run:
  
  ```sh
  sudo ufw status numbered
  sudo ufw delete <number>
  ```
* Verify that UFW has these configuration:
  
  ```sh
  sudo ufw allow 443
  sudo ufw limit 22/tcp
  ```

* If you want port `53` accessible to all:
  
  ```sh
  sudo ufw allow 53/udp
  ```

* If to some specific IP address only:
  
  ```sh
  sudo ufw allow from <ip> proto tcp to any port 53/udp
  ```
  Apply rules:

  ```sh
  sudo ufw reload
  ```
