#!/bin/sh

KNOWN_DOMAINS=()

ssh_installed(){
	local version=$(ssh -V 2>&1)
	if [[ $version ]]; then
		echo "ssh version: $version\n"
	else
		echo "ssh not installed\n"
	fi
}
ssh_agent_running(){
	local agents=$(pgrep ssh-agent)
	if [[ $agents ]]; then
		echo "current ssh-agents:\n$agents\n"
	else
		echo 'unable to find ssh-agent: please run "eval $(ssh-agent)"\n'
	fi
}
ssh_agent_identities(){
	local identities=$(ssh-add -l 2>&1)
	if [[ $identities != "The agent has no identities." ]]; then
		echo "current ssh-identities:\n$identities\n"
	else
		echo 'agent has no identities: please add with "ssh-add ~/.ssh/{ssh-key-name}"\n'
	fi
}
ssh_known_hosts(){
	local host_file=~/.ssh/known_hosts
	local hosts=$(ssh-keygen -lf $host_file)
	if [[ $hosts ]]; then
		for host in $hosts
		do
			local arr=($(echo $host))
			local domain=${arr[3]}
			KNOWN_DOMAINS+=($domain)
		done		
		echo "current known hosts:\n$KNOWN_DOMAINS\n"
	else
		echo 'known hosts file is empty: please add with: "ssh-keyscan {target-host} >> ~/.ssh/known_hosts"\n'
	fi
}
ssh_keys_pub(){
       local keys=$(find ~/.ssh -name "*.pub" -depth 1)
       if [[ $keys ]]; then
               echo "current public keys:\n$keys\n"
       else
               echo 'no keys public keys found: please create a new one with "ssh-keygen -t ed25519 -b 4096 -C "{username@emaildomain.com}" -f {ssh-key-name}"'
       fi
}
ssh_check_knownhost_connect(){
	if [[ $KNOWN_DOMAINS ]]; then
		echo 'connections for knownhost:'
		for domain in $KNOWN_DOMAINS
		do
			ssh -q $domain exit > /dev/null; retcode=$?
			if [[ $retcode ]]; then
				ssh -ql git $domain exit > /dev/null; retcode=$?
				if [[ $retcode != '0' ]]; then
					echo "$domain - returned error code $retcode"
				else
					echo "$domain - successfully connected as git"
				fi
			else	
				echo "$domain - successfully connected without user"
			fi	
		done
	else
		echo "connect test: no know hosts to test"
	fi
}
ssh_installed && ssh_agent_running 
ssh_known_hosts
ssh_keys_pub
ssh_agent_identities
ssh_check_knownhost_connect
