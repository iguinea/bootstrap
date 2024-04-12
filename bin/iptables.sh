

#vim /etc/sysctl.conf
#net.ipv4.ip_forward = 1
sysctl -w net.ipv4.ip_forward=1

REDIS_MASTER_IP=`dig +short -t A testmaria-001.jue30e.0001.euc1.cache.amazonaws.com |grep -v vpc|head -1`
REDIS_READ_ONLY=`dig +short -t A testmaria-002.jue30e.0001.euc1.cache.amazonaws.com |grep -v vpc|head -1`

iptables -A FORWARD -i eth0 -j ACCEPT
iptables -A FORWARD -o eth0 -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 6379 -j DNAT --to ${REDIS_MASTER_IP}:6379 
iptables -A FORWARD -i eth0 -p tcp --dport 6379 -d ${REDIS_MASTER_IP} -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 6380 -j DNAT --to ${REDIS_READ_ONLY}:6379
iptables -A FORWARD -i eth0 -p tcp --dport 6380 -d ${REDIS_READ_ONLY} -j ACCEPT

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

/sbin/iptables-save > /etc/sysconfig/iptables
## Disable firewalld if installed #
# sudo systemctl stop firewalld.service
# sudo systemctl disable firewalld.service
# sudo systemctl mask firewalld.service
## install package on Linux to save iptables rules using the yum command/dnf command ##
# sudo yum install iptables-services
# sudo systemctl enable iptables
# sudo systemctl enable ip6tables
# sudo systemctl status iptables


# Clear all
function iptables_clear (){
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -F
    iptables -t mangle -F
    iptables -F
    iptables -X
    iptables -L
}