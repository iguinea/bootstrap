#!/bin/zsh 

k8s_add_cluster_2_config(){
    PS3="Select cluster to attach to configuration > "
    select cluster in `aws eks list-clusters --query 'clusters[*]' --output text|sed -e 's/\t/\n/g'`; do
        AWS_PAGER= aws sts get-caller-identity --output text
        echo aws eks update-kubeconfig --region $AWS_REGION --name $cluster
        break
    done
}


k8s_contexts(){ 

    PS3="Select cluster to attach to configuration >"
    select context in `kubectl config get-contexts -o name`; do
        echo $context
        break
    done

}

##############################
k8s_templates(){

}


#----------------------------------------------------------------------------
k8s_config(){
    local config_entries=()
    while read entry
    do
        entry=`basename $entry|cut -d\- -f2-`
        config_entries+=("$entry")
    done < <((ls ~/.kube/config-*) 2> /dev/null)
    echo $config_entries

    local k8s_sorted_entries=()
    while IFS= read -rd '' item; do
        k8s_sorted_entries+=("$item")
    done < <(printf '%s\0' "${config_entries[@]}" | sort -z)
    k8s_sorted_entries+="Exit"

    PS3="Select configuration file to be used > "
    select account in "${k8s_sorted_entries[@]}"; do
        if [[ -f ~/.kube/config-$account ]] 
        then
            export KUBECONFIG=~/.kube/config-$account
            echo "KUBECONFIG environemnt var to : ~/.kube/config-$account"
        fi
        break
    done
}


k8s_set_default_config(){
    local config_entries=()
    while read entry
    do
        entry=`basename $entry|cut -d\- -f2-`
        config_entries+=("$entry")
    done < <((ls ~/.kube/config-*) 2> /dev/null)
    echo $config_entries

    local k8s_sorted_entries=()
    while IFS= read -rd '' item; do
        k8s_sorted_entries+=("$item")
    done < <(printf '%s\0' "${config_entries[@]}" | sort -z)
    k8s_sorted_entries+="Exit"

    PS3="Select configuration file to be used > "
    select account in "${k8s_sorted_entries[@]}"; do
        if [[ -f ~/.kube/config-$account ]] 
        then
            ln -sF ~/.kube/config-$account ~/.kube/config
            echo "Set default configuration to: $account"
        fi
        break
    done
}

k8s_hardeneks_report(){
  python3 -m venv /tmp/.venv
  source /tmp/.venv/bin/activate
  pip install hardeneks
  hardeneks --export-html report.html
  open report.html
}
