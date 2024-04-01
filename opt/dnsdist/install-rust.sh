#!/bin/sh
set -v
set -e

readonly QUICHE_VERSION='0.20.1'
readonly QUICHE_TARBALL="${QUICHE_VERSION}.tar.gz"
readonly QUICHE_TARBALL_URL="https://github.com/cloudflare/quiche/archive/${QUICHE_TARBALL}"
readonly QUICHE_TARBALL_HASH='9c460d8ecf6c80c06bf9b42f91201ef33f912e2615a871ff2d0e50197b901c71'

INSTALL_PREFIX=/usr/local
SOEXT=so
if [ $(uname) = Darwin ]; then
  if [ $(id -u) = 0 ]; then
    echo Do not run as root on macOS
    exit 1
  fi
  INSTALL_PREFIX="${HOMEBREW_PREFIX}"
  SOEXT=dylib
fi

cd /tmp
echo $0: Downloading $QUICHE_TARBALL
curl -L -o "${QUICHE_TARBALL}" "${QUICHE_TARBALL_URL}"
# Line below should echo two spaces between digest and name
echo "${QUICHE_TARBALL_HASH}"  "${QUICHE_TARBALL}" | sha256sum -c -
tar xf "${QUICHE_TARBALL}"
cd "quiche-${QUICHE_VERSION}"
RUST_BACKTRACE=1 cargo build --release --no-default-features --features ffi,boringssl-boring-crate --package quiche

sudo install -m644 quiche/include/quiche.h "${INSTALL_PREFIX}"/include
sudo install -m644 target/release/libquiche.${SOEXT} "${INSTALL_PREFIX}"/lib/libdnsdist-quiche.${SOEXT}

if [ $(uname) = Darwin ]; then
  install_name_tool -id "${INSTALL_PREFIX}"/lib/libdnsdist-quiche.${SOEXT} "${INSTALL_PREFIX}"/lib/libdnsdist-quiche.${SOEXT}
fi

if [ ! -d "${INSTALL_PREFIX}"/lib/pkgconfig/ ]; then
    sudo mkdir "${INSTALL_PREFIX}"/lib/pkgconfig/
fi
sudo install -m644 /dev/stdin "${INSTALL_PREFIX}"/lib/pkgconfig/quiche.pc <<PC
# quiche
Name: quiche
Description: quiche library
URL: https://github.com/cloudflare/quiche
Version: ${QUICHE_VERSION}
Cflags: -I${INSTALL_PREFIX}/include
Libs: -L${INSTALL_PREFIX}/lib -ldnsdist-quiche
PC

cd ..
rm -rf "${QUICHE_TARBALL}" "quiche-${QUICHE_VERSION}"
