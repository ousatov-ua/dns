#!/bin/bash
# Next exports for AOCC compiler (AMD)
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=clang
export CXX="clang++"
# Next exports are common
export CFLAGS="-O3 -pipe -march=native -flto"
export CXXFLAGS="-O3 -pipe -march=native -flto"
export CPPFLAGS="-O3 -pipe -march=native -flto"

./configure --enable-dnstap --enable-lto --enable-systemd --with-libcap --with-libcurl=/usr/lib
make
make install

sudo groupadd pdns-recursor
sudo adduser --home /var/lib/pdns-recursor --disabled-login pdns-recursor
sudo usermod -a -G pdns-recursor pdns-recursor
