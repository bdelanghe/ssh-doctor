#!/bin/bash

KNOWN_DOMAINS=()

get_startup_file() {
    local default_shell
    default_shell=$(basename "$SHELL")

    # Print the default shell to stderr
    echo "Default shell: $default_shell" >&2

    case "$default_shell" in
        bash)
            # Prefer BASH env variable, else default to ~/.bashrc
            echo "${BASH:-~/.bashrc}"
            ;;
        zsh)
            # Prefer ZSH env variable for oh-my-zsh setups, else default to ~/.zshrc
            echo "${ZSH:-~/.zshrc}"
            ;;
        # Add checks for other shells if needed
        # ksh) echo ~/.kshrc ;;
        # fish) echo ~/.config/fish/config.fish ;;
        *) return 1 ;;
    esac
}

file_exists_and_readable() {
    local file="$1"
    # Expand tilde and check if file exists and is readable
    if [[ -r "${file/#\~/$HOME}" ]]; then
        return 0
    else
        return 1
    fi
}

check_ssh_agent_startup() {
    local file_to_check
    file_to_check=$(get_startup_file)
    # Check if the shell is unsupported
    if [[ -z "$file_to_check" ]]; then
        echo "Unsupported shell."
        return 1
    fi

    # Use the new function to check if the file exists and is readable
    if ! file_exists_and_readable "$file_to_check"; then
        echo "$file_to_check does not exist or is not readable."
        return 1
    fi

    # Check if the ssh-agent initialization is in the file
    if grep -q "eval \$(ssh-agent" "$file_to_check"; then
        printf "ssh-agent initialization found in %s\n" "$file_to_check"
        return 0
    else
        printf "ssh-agent initialization not found in %s.\n" "$file_to_check"
        return 1
    fi
}


add_ssh_agent_startup() {
    local file_to_check
    file_to_check=$(get_startup_file)
    if [[ $? -ne 0 ]]; then
        echo "Unsupported shell."
        return 1
    fi

    if [[ ! -r $file_to_check ]]; then
        touch "$file_to_check"
        echo "$file_to_check created."
    fi

    echo "eval \$(ssh-agent)" >> "$file_to_check"
    echo "ssh-agent initialization added to $file_to_check"
}

# Usage
check_ssh_agent_startup || add_ssh_agent_startup

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
            # Exclude lines that start with '|', which indicates a hashed host
            if [[ $line != \|* ]]; then
                local domain
                # Split by space and get the first field which is the host name.
                domain=$(echo "$line" | awk '{print $1}')
                if ! [[ "${KNOWN_DOMAINS[@]}" =~ "${domain}" ]]; then
                    KNOWN_DOMAINS+=("$domain")
                fi
            fi
        done < "$host_file"
        
        printf "current known hosts:\n"
        IFS=$'\n' sorted=($(sort <<<"${KNOWN_DOMAINS[*]}"))
        unset IFS
        printf "%s\n" "${sorted[@]}"
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
		for domain in "${KNOWN_DOMAINS[@]}"; do
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
check_ssh_agent_startup || add_ssh_agent_startup
ssh_installed && ssh_agent_running
ssh_known_hosts
ssh_keys_pub
ssh_agent_identities
# ssh_check_knownhost_connect
