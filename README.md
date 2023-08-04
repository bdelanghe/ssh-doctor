# SSH Doctor 🩺

The SSH Doctor is a Bash script designed to diagnose common issues with SSH setup. It provides functionality to check:

- If SSH is installed and its version.
- If the SSH agent is running and lists all current agents.
- Lists all the identities currently added to the SSH agent.
- Lists all known hosts from the SSH configuration.
- Lists all SSH public keys.
- Checks if it can connect to all known hosts.

These checks can help troubleshoot issues with SSH configuration and connectivity. It is a handy tool for those who rely on SSH for secure remote operations. 

## Usage
Simply run the script from your terminal:
```bash
./ssh_doctor.sh
```
The script will then provide a detailed status report, checking your SSH setup and offering advice on how to fix any identified issues.

This script was made to alleviate the process of checking SSH configuration, especially for those who work with SSH frequently. It's your personal SSH physician. Stay healthy in the SSH world!

Please note: This script is meant to diagnose issues, not solve them. Always be careful when changing your SSH configuration. If you're unsure, consult the man pages or other trustworthy resources.
