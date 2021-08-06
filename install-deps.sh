#! /usr/bin/env bash

# Required by interledger-rs
sudo apt-get update
sudo apt-get install -y redis-server redis-tools libssl-dev
sudo npm install -g ganache-cli ilp-settlement-xrp conventional-changelog-cli
# Required for llvm-profdata && llvm-cov (https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html)
sudo apt-get install -y jq
rustup toolchain install nightly
cargo install rustfilt
# Required for lcov to HTML generation
sudo apt-get install -y lcov

# NOPE!! --> rustup component add llvm-tools-preview
# ??? cargo install cargo-binutils

function install_llvm_12() {
    sudo apt-get update
    sudo apt-get install llvm-12 -y
    sudo bash ./update-alternatives-clang.sh 12 1
}

UBUNTU_VER=`lsb_release -r | grep -o -P "\d+\.\d+"`

case $UBUNTU_VER in
    "18.04")
        if (! dpkg -l | grep -q llvm-12) && (! grep -q "llvm-toolchain-bionic-12" /etc/apt/sources.list); then
            # Based on https://apt.llvm.org/
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 15CF4D18AF4F7421
            cat <<EOT | sudo tee -a /etc/apt/sources.list >> /dev/null
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main
EOT
        fi
        install_llvm_12
        ;;
    "20.04")
        install_llvm_12
        ;;
    *)
        echo "Please install LLVM >= v.11 manually!"
        ;;
esac
