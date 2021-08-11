#! /usr/bin/env bash
#
# This script install deps for ALL the coverage toolsets, except for cargo-tarpaulin
# Tested only on Ubuntu 18.04 & 20.04
#
# Required by interledger-rs
sudo apt-get update
sudo apt-get install -y redis-server redis-tools libssl-dev
sudo npm install -g ganache-cli ilp-settlement-xrp conventional-changelog-cli
# Resuired by most of the coverage toolsets (grcov, llvm, gcov)
rustup toolchain install nightly
# Required when using llvm-profdata & llvm-cov manually, as described here
# https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
cargo install rustfilt
sudo apt-get install -y jq
# Used to generate HTML reports from lcov *.info and GCC/gcov *.gcda/*.gcno files
sudo apt-get install -y lcov

# https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
# requires that LLVM version is >= 11.0
function install_llvm_12() {
    sudo apt-get update
    sudo apt-get install llvm-12 -y
    sudo bash ./update-alternatives-clang.sh 12 1
}

UBUNTU_VER=`lsb_release -r | grep -o -P "\d+\.\d+"`

# llvm tools are either used directly or required by grcov
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

        # Required for *.gcda/*.gcno parsing on Ubuntu 20.04, as the default gcc-9
        # is incomaptible with *.gcda/*.gcno version produced by rustc
        sudo apt-get install -y gcc-7
        sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 1 
        sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-7 1 
        ;;
    *)
        echo "Please install LLVM >= v.11 manually!"
        ;;
esac

# https://github.com/mozilla/grcov
cargo install grcov
# Required for grcov, must be installed after the correct version of LLVM is in the system
rustup component add llvm-tools-preview --toolchain nightly
