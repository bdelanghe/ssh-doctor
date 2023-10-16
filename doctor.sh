#!/bin/bash

KNOWN_DOMAINS=()

ssh_installed() {
	local version
	version=$(ssh -V 2>&1)
	if [[ $version ]]; then
		printf 'ssh version:%s\n' "$version"
	else
		printf "ssh not installed\n"
	fi
}
ssh_agent_running() {
	local agents
	agents=$(pgrep ssh-agent)
	if [[ $agents ]]; then
		printf 'current ssh-agents:\n%s\n' "$agents"
	else
		# shellcheck disable=SC2016
		printf 'unable to find ssh-agent: please run "eval $(ssh-agent)"\n'
	fi
}
ssh_agent_identities() {
	local identities
	identities=$(ssh-add -l 2>&1)
	if [[ $identities != "The agent has no identities." ]]; then
		printf 'current ssh-identities:\n%s\n' "$identities"
	else
		# shellcheck disable=SC2016
		printf 'agent has no identities: please add with "ssh-add ~/.ssh/{ssh-key-name}"\n'
	fi
}
ssh_known_hosts() {
    local host_file
    local line
    host_file=~/.ssh/known_hosts
    if [[ -f $host_file ]]; then
        while IFS= read -r line; do
            local domain
            domain=$(echo "$line" | awk '{print $NF}')
            KNOWN_DOMAINS+=("$domain")
        done < <(ssh-keygen -lf "$host_file")
        
        printf "current known hosts:\n"
        for known in "${KNOWN_DOMAINS[@]}"; do
            echo "$known"
        done
    else
        printf 'known hosts file is empty: please add with: "ssh-keyscan {target-host} >> ~/.ssh/known_hosts"\n'
    fi
}

ssh_keys_pub() {
	local keys
	keys=$(find ~/.ssh -name "*.pub" -depth 1)
	if [[ $keys ]]; then
		printf 'current public keys:\n%s\n' "$keys"
	else
		echo 'no keys public keys found: please create a new one with "ssh-keygen -t ed25519 -b 4096 -C "{username@emaildomain.com}" -f {ssh-key-name}"'
	fi
}
ssh_check_knownhost_connect() {
	if [[ ${KNOWN_DOMAINS[0]} ]]; then
		echo 'connections for knownhost:'
		for domain in $KNOWN_DOMAINS; do
			ssh -q "$domain" exit >/dev/null
			retcode=$?
			if [[ $retcode ]]; then
				ssh -ql git "$domain" exit >/dev/null
				retcode=$?
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
