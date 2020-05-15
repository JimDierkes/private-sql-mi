#cloud-config
write_files:
- owner: root:root
  path: /usr/bin/configureForwarding/configureForwarding.sh
  content: |
    #!/bin/bash
    # Reference
    #  + https://unix.stackexchange.com/questions/20784/how-can-i-resolve-a-hostname-to-an-ip-address-in-a-bash-script
    #

    # Services by ports
    declare -A serviceArray
    serviceArray[1433]="mssql"
    serviceArray[80]="http"
    serviceArray[443]="https"

    # Gather input parameters and convert from comma separated string to Array
    OIFS=$IFS;
    IFS=",";

    fqdnStr="${fqdn_list}";
    fqdnArray=($fqdnStr);

    srcPortStr="${source_port_list}";
    srcPortArray=($srcPortStr);

    dstPortStr="${destination_port_list}";
    dstPortArray=($dstPortStr);

    for ((i=0; i<$${#fqdnArray[@]}; ++i)); 
    do     
      h=$${fqdnArray[$i]}
      srcPort=$${srcPortArray[$i]}
      dstPort=$${dstPortArray[$i]}
      service=$${serviceArray[$dstPort]}

      host $h 2>&1 > /dev/null
      if [ $? -eq 0 ] 
      then
        ip=`host $h | awk '/has address/ { print $4 }'`

        if [ -n "$ip" ]; then
          echo "[$(date +%F_%T)] $h IP is $ip"
        else
          echo "[$(date +%F_%T)] ERROR: $h is a FQDN but could not resolve hostname $h"
          exit 1
        fi
      else
        echo "[$(date +%F_%T)] ERROR: $h is not a FQDN"
        exit 2
      fi

      forwardPorts=`sudo firewall-cmd --zone=public --list-forward-ports`

      if [ -n "$forwardPorts" ]
      then
        toaddr=""
        for property in $(echo $forwardPorts | tr ":" "\n")
        do
          toaddr=`echo $property | awk -F"=" '/toaddr/ { print $2 }'`
        done
        if [ $ip == $toaddr ]
        then
          echo "[$(date +%F_%T)] No changes in IP $ip for $h"
        else
          echo "[$(date +%F_%T)] Changing port forwarding for $h from $toaddr to $ip"
          sudo firewall-cmd --permanent --zone=public --remove-forward-port=port=$srcPort:proto=tcp:toport=$dstPort:toaddr=$toaddr > /dev/null
          sudo firewall-cmd --permanent --zone=public --add-forward-port=port=$srcPort:proto=tcp:toport=$dstPort:toaddr=$ip > /dev/null
          sudo firewall-cmd --reload > /dev/null
        fi
      else
        echo "[$(date +%F_%T)] Configuring port forwarding for $h to $ip"
        sudo firewall-cmd --permanent --zone=public --add-service=$service > /dev/null
        sudo firewall-cmd --permanent --zone=public --add-masquerade > /dev/null
        sudo firewall-cmd --permanent --zone=public --add-forward-port=port=$srcPort:proto=tcp:toport=$dstPort:toaddr=$ip > /dev/null
        sudo firewall-cmd --reload > /dev/null
      fi

    done
    IFS=$OIFS;
  permissions: '0755'
  
- content: |
    * * * * * /usr/bin/configureForwarding/configureForwarding.sh
  path: ~/mycron
  permissions: '0755'

runcmd:
  - cd "/usr/bin/configureForwarding"
  - ./configureForwarding.sh
  - crontab ~/mycron
  - /bin/rm -rf ~/mycron