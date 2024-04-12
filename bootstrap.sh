#!/bin/zsh

echo "[+] Install BREW [+]"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "[+] Install Ansible and Git [+]"
brew install ansible git

echo "[+] Install apps [+]"
ansible-playbook -i inventory.ini bootstrap.yaml