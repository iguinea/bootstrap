#!/bin/zsh 
AWS_ACCOUNT_DETAILS=~/bin/aws_accounts.csv
aws_accounts=(ProductoInterno-Dev ProductoInterno-Prod EmoryDemos CxLinkVoice-Dev CxLinkVoice-Prod Connect4SAP Quit)
HEADER_COLUMS='
InstanceID;State;KeyPair;IP;EC2Type;Name;Owner;Product;Project;StopTag
'
args() { echo $#; }

function aws_sso(){
    aws sso login --sso-session cxlink
    aws_sso_profile $1
}

function aws_sso_profile(){

    profile_arg=$1
    if [[ x${profile_arg} == x"" ]] 
    then
    select profile in `~/bin/cxlink-sso --list`; do
        echo "Adding profile $profile to credentials file and setting environment variables"
        ~/bin/cxlink-sso --profile $profile --add2credentials
        #echo $profile
        export AWS_PROFILE=$profile
        export AWS_PAGER=''
        aws_setregion
        export|grep ^AWS_
        break
    done
    else 
        ~/bin/cxlink-sso --profile $profile_arg --add2credentials
        #echo $profile
        export AWS_PROFILE=$profile
        export AWS_PAGER=''
        aws_setregion
        export|grep ^AWS_
        break
    fi

    
}

function aws_ec2() {
   # aws_getcredentials 

    ## Parse start stop commands
    DESCRIBE=0
    START=0
    STOP=0
    WITH_ACTION=0
    DETAIL=1
    SSM=0
    SEARCH_STRINGS=()
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            --ssm)
                DESCRIBE=0
                START=0
                STOP=0
                WITH_ACTION=0
                SSM=1
                shift
                ;;
            --start)
                DESCRIBE=0
                START=1
                STOP=0
                WITH_ACTION=1
                shift
                ;;
            --stop)
                DESCRIBE=0
                START=0
                STOP=1
                WITH_ACTION=1
                shift
                ;;
            --describe)
                DESCRIBE=1
                START=0
                STOP=0
                WITH_ACTION=1
                shift
                ;;
            --detail)
                DETAIL=1
                shift
                ;;
            *)    # unknown option
                SEARCH_STRINGS+=("$1") # save it in an array for later
                shift
                ;;
        esac
    done
    set -- "${SEARCH_STRINGS[@]}" # restore positional parameters
    #echo  ${SEARCH_STRINGS[@]}



    HEADER=$HEADER_COLUMS
    DATA=$(aws ec2 describe-instances |
        jq \
            '(.Reservations[].Instances[])? | 
            [   
                .InstanceId,
                .State.Name,
                (.KeyName // false),
                (.PrivateIpAddress // false),
                .InstanceType,
                (([.Tags[] | select(.Key=="Name") | .Value ][0])? // false),
                (([.Tags[] | select(.Key=="Owner") | .Value ][0]) // false),
                (([.Tags[] | select(.Key=="Product") | .Value ][0]) // false),
                (([.Tags[] | select(.Key=="Project") | .Value ][0]) // false),
                (([.Tags[] | select(.Key | startswith("Stop-")) | .Key ][0]))
            ] | join(";")' | \
            sed -e 's/\"//g' | sort -t";" -k 10 -k 7 -k 6 )


    DATA=${HEADER}${DATA}
    DATA=$(echo "$DATA"  | column -s\; -t -x )

    #https://misc.flogisoft.com/bash/tip_colors_and_formatting
    #https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
    
    # PRINT HEADER WITH SEPARATOR
    HEADER_DATA=$(echo "$DATA" | head -n 1)
    echo "$HEADER_DATA"
    chrlen=${#HEADER_DATA}
    s=$(printf "%-${chrlen}s" "-")
    echo "${s// /-}"

    # Filter by passed arguments
    for arg in "${SEARCH_STRINGS[@]}"; do
        DATA=$(echo "$DATA" | GREP_COLOR="1;30;105" grep --color=always -i $arg)
    done

    STOP_LIST=()
    START_LIST=()
    DESCRIBE_LIST=()
    SSM_LIST=()
    ## search

    # Check if argument was passed
    if [[ x"${SEARCH_STRINGS[@]}" != x"" ]]; then
        while IFS= read -r line; do
            instanceid=$(echo "$line" | awk '{ print $1 }')
            ec2_status=$(echo "$line" | awk '{ print $2 }')
            DESCRIBE_LIST+=("$instanceid")
            case $ec2_status in
                "terminated")
                    [ $WITH_ACTION = 0 ] && echo "$line" | GREP_COLOR="1;30;103" grep --color=always -e "terminated"
                    ;;
                "stopped")
                    echo "$line" | GREP_COLOR="1;97;41" grep --color=always -e "stopped"
                    START_LIST+=("$instanceid")
                    ;;
                "stopping")
                    [ $WITH_ACTION = 0 ] && echo "$line" | GREP_COLOR="1;30;103" grep --color=always -e "stopping"
                    ;;
                "shutting-down")
                    [ $WITH_ACTION = 0 ] && echo "$line" | GREP_COLOR="1;30;103" grep --color=always -e "shutting-down"
                    ;;
                "pending")
                    [ $WITH_ACTION = 0 ] && echo "$line" | GREP_COLOR="1;30;103" grep --color=always -e "pending"
                    ;;
                "rebooting")
                    [ $WITH_ACTION = 0 ] && echo "$line" | GREP_COLOR="1;30;105" grep --color=always -e "rebooting"
                    ;;
                "running")
                    echo "$line" | GREP_COLOR="1;97;42" grep --color=always -e "running"
                    STOP_LIST+=("$instanceid")
                    SSM_LIST+=("$instanceid")
                    ;;
            esac
        done < <(printf '%s\n' "$DATA")

        [ $WITH_ACTION = 1 ] && echo ""
        # --ssm
        if [ $SSM = 1 ]
        then
            ids=""
            for id in ${SSM_LIST[@]}
            do 
                id=${id%$'\n'}
                ids=${ids}" "${id}
            done 
            ids=`echo $ids|sed -e 's/^\ //'`
            if [ x"$ids" != x"" ]
            then
                echo aws ssm start-session --target  $(printf '%s\n' "$ids")
                aws ssm start-session --target  $(printf '%s\n' "$ids")
            fi
            
        fi
        # --stop
        if [ $STOP = 1 ] && [ $START = 0 ] && [ $DESCRIBE = 0 ]
        then
            ids=""
            for id in ${STOP_LIST[@]}
            do 
                id=${id%$'\n'}
                ids=${ids}" "${id}
            done 
            ids=`echo $ids|sed -e 's/^\ //'`
            if [ x"$ids" != x"" ]
            then
                aws ec2 stop-instances --instance-ids $(printf '%s\n' "$ids") --output table
            fi
        fi
        # --start
        if [ $STOP = 0 ] && [ $START = 1 ] && [ $DESCRIBE = 0 ]
        then
            ids=""
            for id in ${START_LIST[@]}
            do 
                id=${id%$'\n'}
                ids=${ids}" "${id}
            done 
            ids=`echo $ids|sed -e 's/^\ //'`
            if [ x"$ids" != x"" ]
            then
                aws ec2 start-instances --instance-ids $(printf '%s\n' "$ids")  --output table
            fi
        fi
        # --describe
        if [ $STOP = 0 ] && [ $START = 0 ] && [ $DESCRIBE = 1 ]
        then
            for id in ${DESCRIBE_LIST[@]}
            do 
                aws ec2 describe-instances --instance-id $id --output table --query 'Reservations[*].Instances[*]' 
            done 
        fi
    else
        echo "$DATA" | GREP_COLOR="1;97;41" grep --color=always -e "terminated"
        echo "$DATA" | GREP_COLOR="1;97;41" grep --color=always -e "stopped"
        echo "$DATA" | GREP_COLOR="1;30;103" grep --color=always -e "stopping"
        echo "$DATA" | GREP_COLOR="1;30;103" grep --color=always -e "shutting-down"
        echo "$DATA" | GREP_COLOR="1;30;103" grep --color=always -e "pending"
        echo "$DATA" | GREP_COLOR="1;97;105" grep --color=always -e "rebooting"
        echo "$DATA" | GREP_COLOR="1;97;42" grep --color=always -e "running"
    fi
    
    echo ""
}

#function aws_getenvs() {
#    echo ""
#    for arg in AWS_ACCOUNT AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION; do
#        
#        echo "declare -x "$arg=${!$arg}
#    done
#    echo ""
#}

aws_ec2describe(){
    aws ec2 describe-instances --instance-id $1 --output table --query 'Reservations[*].Instances'
}

aws_setregion(){
    aws_regions=(`AWS_PAGER= aws ec2 describe-regions --region eu-west-1 --query 'Regions[*].RegionName' --output  text`)
    echo "Select AWS Region to operate into: "
    PS3="> "
    select region in $aws_regions; do
        export AWS_REGION=$region
        export AWS_DEFAULT_REGION=$region
        break
    done
    
}

# function aws_setenvs sets the proper environment variables for AWS cli
aws_setenvs() {
    num_args=$(args $aws_accounts)
    echo "Select AWS Account to set environment variables to: "
    PS3="> "
    select account in ${aws_accounts}; do
        [[ $account == "Quit" ]] && break
        echo "You selected $account ($REPLY)"
        vMFAProfile=""
        vMFSAccountNumber=""
        vMFAAccountUsername=""
        vAWSAccount=""
        vAssumeRole=""
        vProfileName=""
        vMFALongSuffix=""
        vDefaultPem=""
        while IFS="," read -r item profilename assumerolename awsaccount region duration mfaprofile mfaaccountnumber mfaaccountusername mfalongsuffix defaultpem
        do
            vProfileName=$profilename
            vAssumeRole=$assumerolename
            vAWSAccount=$awsaccount
            vMFAProfile=$mfaprofile
            vMFAAccountNumber=$mfaaccountnumber
            vMFAAccountUsername=$mfaaccountusername
            vMFALongSuffix=$mfalongsuffix
            vMFADuration=$duration
            export AWS_REGION=$region
            export AWS_DEFAULT_REGION=$region
            export AWS_PROFILE=$mfaprofile-$profilename
            export AWS_ACCOUNT=${account} # this is a custom variable, used in get_credentials to select with account to use
            vDefaultPem=$defaultpem
        echo ""
        done < <(grep ^$account $AWS_ACCOUNT_DETAILS )
        kp_otp "aws"
        #totp=$(pbpaste)
        
        #echo "TOTP = "$totp
        ssh-add -D
        ssh-add $vDefaultPem
        echo "ssh-add $vDefaultPem"

        echo "AWS_PROFILE=${vMFAProfile} MFA_STS_DURATION=${vMFADuration} MFA_DEVICE=arn:aws:iam::${vMFAAccountNumber}:mfa/${vMFAAccountUsername} MFA_ASSUME_ROLE=arn:aws:iam::${vAWSAccount}:role/${vAssumeRole} aws-mfa --log-level NOTSET --force --short-term-suffix ${vProfileName} --long-term-suffix ${vMFALongSuffix}"
        pbpaste | AWS_PROFILE=${vMFAProfile} MFA_STS_DURATION=${vMFADuration} MFA_DEVICE=arn:aws:iam::${vMFAAccountNumber}:mfa/${vMFAAccountUsername} MFA_ASSUME_ROLE=arn:aws:iam::${vAWSAccount}:role/${vAssumeRole} aws-mfa --log-level NOTSET --force --short-term-suffix ${vProfileName} --long-term-suffix ${vMFALongSuffix}
        
        break
    done
}


# aws_cloudwatchlist
function aws_cloudwatchlist() {
    #pip3 install awslogs
    #aws_getcredentials 

    for i in $(awslogs groups); do
        # Filter by passed arguments
        for arg in "$@"; do
            i=$(echo "$i" | GREP_COLOR="1;30;105" grep --color=always -i $arg)
        done
        [ x"$i" != x"" ] && echo "awslogs get $i -w -G -S"
    done
}

#aws_region will select 
#function aws_region(){
#    #aws_check_envs_constraint
#    #[ x"$?" == x"1" ] && return 1
#    DATA=$(aws ec2 describe-regions|jq '.Regions[]| [.RegionName][0]'|sed -e 's/\"//g')
#    select region in ${DATA[*]}; do
#        export AWS_REGION=$region
#        export AWS_DEFAULT_REGION=$region
#        break
#    done
#}


function aws_ips() {
    region=$1
    service=$2
    if [[ x${region} == x"" ]] 
    then
        echo "Please select one region as first parameter for this command:"
        wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json |\
            jq '.prefixes[].region' |\
            sort | uniq | sed -e 's/\"//g'
    elif [[ x${2} == x"" ]] 
    then
        echo "Please select a service as second parameter for this command:"
        wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json |\
            jq --arg region $region '.prefixes[] | select( .region | contains($region) ) | .service' |\
            sort | uniq | sed -e 's/\"//g'
    else
        echo "List of IPs for selected service"
        wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json |\
            jq --arg region $region --arg service $service ' .prefixes[] | select( .region | contains($region) ) | select( .service | contains($service) ) | .ip_prefix' |\
            sort | uniq | sed -e 's/\"//g'
    fi
}

function aws_s3clearbucketoffailedmultipartuploads(){

    local tmpFile="/tmp/aws_s3clearbucketoffailedmultipartuploads.$$"
    aws s3api list-multipart-uploads --bucket ${1} |grep 'UploadId\|Key' > ${tmpFile}
    cat ${tmpFile} | grep UploadId | sed -e 's/\"//g' -e 's/\ //g' -e 's/\,//g' | cut -d\: -f2 > ${tmpFile}.id
    cat ${tmpFile} | grep Key      | sed -e 's/\"//g' -e 's/\ //g' -e 's/\,//g' | cut -d\: -f2 > ${tmpFile}.key
    num=`wc -l ${tmpFile}.id|awk '{ print $1 }'`
    for i in `seq $num `
    do
        
        ID=`awk -v my_var=$i 'NR==my_var' ${tmpFile}.id`
        Key=`awk -v my_var=$i 'NR==my_var' ${tmpFile}.key`
        
        echo "Deleting "$Key" multiparts"
        aws s3api abort-multipart-upload --bucket ${1} --key $Key --upload-id $ID
    done 
    rm ${tmpFile}
    rm ${tmpFile}.key
    rm ${tmpFile}.id
}

