#!/bin/zsh 
mac_wifi_decode(){
    echo CalcWLAN by a.s.r

    if [ $# -ne 2 ]
    then
        echo "Usage: $0  "
        echo
        echo "Example: $0 WLAN_C58D 64:68:0C:C5:C5:90"
        return 
    fi

    HEAD=$(echo -n "$1" | tr 'a-z' 'A-Z' | cut -d_ -f2)
    BSSID=$(echo -n "$2" | tr 'a-z' 'A-Z' | tr -d :)
    BSSIDP=$(echo -n "$BSSID" | cut -c-8)
    KEY=$(echo -n bcgbghgg$BSSIDP$HEAD$BSSID | md5sum | cut -c-20)

    echo "La puta clave es $KEY"
}
mac_setDNSs(){
    local interfaces=()
    while read  entry
    do
            interfaces+=("$entry")
    done < <(networksetup -listallnetworkservices|grep -v " denotes that a network service is disabled." 2> /dev/null)
    interfaces+=("Exit")

    local dns_services=()
    #dns_services+=("1.1.1.1")
    dns_services+=("208.67.222.222")
    dns_services+=("208.67.220.220")

    select interface in $interfaces; do
        [[ $interface == "Exit" ]] && break
        select dns_service in $dns_services; do
            networksetup -setdnsservers "$interface" $dns_service
            break
        done
        break
    done

}

mac_getProcessOfPort(){
    lsof -i -P | grep LISTEN | grep :$1
}

mac_renameExtension(){
 for file in ./**/*.VIDEO_AUDIO; do
    mv "$file" "${file%.VIDEO_AUDIO}.mp4"
 done

}

acloudguru_create_index () {
    for dirname in ./*/; 
    do
        cd $dirname; 
        echo $dirname|cut -d\/ -f2 |cut -d\.  -f1;
        echo ""
        for i in ./*.mp4; 
        do 
            echo $i|cut -d\/ -f2- |cut -d\.  -f1; 
        done 2>/dev/null 
        cd ..
        echo ""
        echo ""
        echo ""
    done
}