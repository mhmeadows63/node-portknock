#! /bin/sh --noprofile
PATH=/usr/sbin:/usr/bin

declare -a commands=() port
case "$1" in
    persist) # persist [ipv4|ipv6] ports ...
        permanent=' --permanent'
        ;&
        
    load) # load [ipv4|ipv6] ports ...
        echo $@; shift
        if [[ "$1" =~ ipv[46] ]]; then
            fams="$1"; shift
        else
            fams='ipv4 ipv6'
        fi
        port=(${@})
        for fam in ${fams}; do
            [[ "$fam" =~ ipv ]] || continue
            for (( i = 0 ; i < ${#port[@]} ; ++i )); do
                commands+=("firewall-cmd$permanent --direct --add-chain ${fam} filter SSH_knock$i")
                [ $i -gt 0 ] && commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -m recent --name KNOCK$i --remove");
                commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -p udp --dport ${port[$i]} -m recent --name KNOCK$(($i + 1)) --set -j DROP")
                [ $i -gt 0 ] && commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -j SSH_knock0");
            done
            commands+=("firewall-cmd$permanent --direct --add-chain ${fam} filter SSH_knock$i")
            [ $i -gt 0 ] && commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -m recent --name KNOCK$i --remove");
            commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -p tcp --dport 22 -j ACCEPT")
            [ $i -gt 0 ] && commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter SSH_knock$i   5 -j SSH_knock0");

            for (( i = $i ; i > 0 ; --i )); do
                commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter INPUT_direct 5 -m recent --name KNOCK$i --rcheck -j SSH_knock$i")
            done
            commands+=("firewall-cmd$permanent --direct --add-rule  ${fam} filter INPUT_direct 5 -j SSH_knock0")
        done
        commands+=("firewall-cmd$permanent --add-rich-rule='rule family=\"ipv6\" source address=\"fe80::/16\" port port=\"22\" protocol=\"tcp\" accept'")
        commands+=("firewall-cmd$permanent --remove-service=ssh")
        for ((i = 0 ; i < ${#commands[@]} ; ++i)); do
            echo -n "${commands[$i]} # "
            eval "${commands[$i]}"
        done
        ;;

    unpersist) # unpersist
        permanent=' --permanent'
        ;&
        
    unload) # unload
        echo $@
        declare -a commands=() # build the list in creation order then run in reverse
        for family in ipv4 ipv6; do
            for chain in $(firewall-cmd$permanent --direct --get-chains $family filter); do
                [[ "$chain" =~ SSH_knock ]] || continue
                commands+=("firewall-cmd$permanent --direct --remove-chain $family filter $chain")
                eval $(firewall-cmd$permanent --direct --get-rules $family filter $chain | while read rule; do
                    echo "commands+=('firewall-cmd$permanent --direct --remove-rule $family filter $chain $rule')"
                done)
            done
            eval $(firewall-cmd$permanent --direct --get-rules $family filter INPUT_direct | while read rule; do
                [[ "$rule" =~ SSH_knock ]] || continue
                echo "commands+=('firewall-cmd$permanent --direct --remove-rule $family filter INPUT_direct $rule')"
            done)
        done
        commands+=("firewall-cmd$permanent --remove-rich-rule='rule family=\"ipv6\" source address=\"fe80::/16\" port port=\"22\" protocol=\"tcp\" accept'")
        commands+=("firewall-cmd$permanent --add-service=ssh")

        for (( i = ${#commands[@]} - 1 ; i >= 0 ; --i )); do # run in reverse
            echo -n "${commands[$i]} # "
            eval "${commands[$i]}"
        done
        ;;

    *)
        echo "usage $0 [load|unload|persist|unpersist] <args>"
        exit 1
        ;;
esac
exit 0
