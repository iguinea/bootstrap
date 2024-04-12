#!/bin/zsh

source ~/bin/kp_functions.zsh
source ~/bin/aws_functions.zsh
source ~/bin/mac_functions.zsh
source ~/bin/vpn.zsh
source ~/bin/k8s_functions.zsh
source ~/bin/docker_functions.zsh
source ~/bin/backup.zsh
function git_sync_repo() {
  git branch -r | grep -v '\->' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
  git fetch --all
  git pull --all

}

function ssh_socks_hana() {
  ssh -D 1337 -q -C -N  Emory-AWS-Hana
}

# 1password agent
 export SSH_AUTH_SOCK=~/.1password/agent.sock

