#!/usr/bin/env bash
set -eo pipefail

target_hostname=""
target_host=""
secrets_key="$(realpath ~/.ssh/id_ed25519)"
config_repo="git@github.com:and-mel/nixconf.git"
secrets_repo="git@github.com:and-mel/nixconf-secrets.git"

config_flake="$(realpath ~/nixos)"
secrets_flake="$(realpath ~/secrets)"

temp=$(mktemp -d)

function cleanup() {
  rm -rf "$temp"
}
trap cleanup exit

function red() {
	echo -e "\x1B[31m[!] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[31m[!] $($2) \x1B[0m"
	fi
}
function green() {
	echo -e "\x1B[32m[+] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[32m[+] $($2) \x1B[0m"
	fi
}
function yellow() {
	echo -e "\x1B[33m[*] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[33m[*] $($2) \x1B[0m"
	fi
}

function yes_or_no() {
	while true; do
		read -rp "$* [Y/n]: " yn
		yn=${yn:-y}
		case $yn in
		[Yy]*) return 0 ;;
		[Nn]*) return 1 ;;
		esac
	done
}

function retry() {
  local n=1
  local max_retries=3
  local delay=2
  local command="$@"

  until $command; do
    if [[ $n -ge $max_retries ]]; then
      red "Error: Command failed after $max_retries attempts." >&2
      return 1
    fi
    red "Command failed. Attempt $n/$max_retries, retrying in $delay seconds..." >&2
    ((n++))
    sleep $delay
  done
}

function help_and_exit() {
	echo
	echo "Installs NixOS using this nix-config."
	echo
	echo "USAGE: $0 -n=<target_hostname> [OPTIONS]"
	echo
	echo "ARGS:"
	echo "  -n=<target_hostname>      specify hostname of the host to install."
	echo
	echo "OPTIONS:"
	echo "  --debug                   Enable debug mode."
	echo "  -h | --help               Print this help."
	exit 0
}

# Handle command-line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-n=*)
		target_hostname="${1#-n=}"
		;;
	-a=*)
		target_host="${1#-a=}"
		;;
	-k=*)
		secrets_key=$(realpath "${1#-k=}")
		;;
	-f=*)
		config_flake=$(realpath "${1#-f=}")
		;;
	-s=*)
		secrets_flake=$(realpath "${1#-s=}")
		;;
	--temp-override=*)
		temp="${1#--temp-override=}"
		;;
	--debug)
		set -x
		;;
	-h | --help) help_and_exit ;;
	*)
		echo "Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

function generate_ssh_keys() {
  mkdir -p "${temp}/etc/ssh"
  green "Generating host key"
  ssh-keygen -t ed25519 -N "" -f "${temp}/etc/ssh/ssh_host_ed25519_key" -q -C ""
  green "Adding GitHub to known hosts"
  ssh-keyscan -p 22 "github.com" >>~/.ssh/known_hosts || true
}

function init_flakes() {
  export GIT_AUTHOR_NAME="NixOS Installer"
  export GIT_AUTHOR_EMAIL="88601482+and-mel@users.noreply.github.com"
  export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
  export GIT_SSH_COMMAND="ssh -i ${secrets_key}"
  timestamp=$(date +%s)
  green "Validating host"
  host_in_flake="$(nix flake show "${config_flake}" --extra-experimental-features "nix-command flakes" --all-systems --json | yq ".nixosConfigurations | has(\"${target_hostname}\")" - )"
  if [ ${host_in_flake} != "true" ] || [ ! -d "${config_flake}/hosts/${target_hostname}" ]; then
    red "ERROR: Hostname ${target_hostname} doesn't exist in config flake or the hosts directory! Double-check the flake."
    exit 1
  fi
  cd "${secrets_flake}"
  green "Adding new ssh key to secrets.nix"
  yq -i ".systems.${target_hostname} = \"$(head -1 "${temp}/etc/ssh/ssh_host_ed25519_key.pub" | xargs)\"" "${secrets_flake}/secrets.json"
  agenix -r -i "${secrets_key}"
  git add .
  git commit -m "[installer] ${timestamp}: Rekey for host ${target_hostname}" || true
  green "Pre-installation finished."
}

function prepare_git() {
  cd "${secrets_flake}"
  green "push secrets"
  git push -q
  cd "${config_flake}"
  green "nix flake update mysecrets"
  nix flake update mysecrets --extra-experimental-features "nix-command flakes"
}

function copy_files() {
    green "Copying files"
    mkdir -p "${temp}/nix/persist/etc/ssh"
    cp "${temp}/etc/ssh/ssh_host_ed25519_key" "${temp}/nix/persist/etc/ssh/ssh_host_ed25519_key"
    cp "${temp}/etc/ssh/ssh_host_ed25519_key.pub" "${temp}/nix/persist/etc/ssh/ssh_host_ed25519_key.pub"
    mkdir -p "${temp}/home/andrei"
    cp -r "${config_flake}" ${temp}/home/andrei/nixos
    cp -r "${secrets_flake}" ${temp}/home/andrei/secrets
}

function nixos_anywhere() {
    copy_files
    green "Running NixOS Anywhere"
    yellow "flake ${config_flake}#${target_hostname}"
    yellow "target-host ${target_host}"
    nixos-anywhere --flake "${config_flake}#${target_hostname}" \
        --extra-files "${temp}" --chown /home/andrei 1000:100 \
        --generate-hardware-config nixos-generate-config "/home/andrei/nixos/hosts/${target_hostname}/hardware-configuration.nix" \
        --target-host "${target_host}"
}

# Validate required options
if [ -z "${target_hostname}" ] || [ -z "${target_host}" ]; then
	red "ERROR: -n and -a are required"
	echo
	help_and_exit
fi

echo "This script will install NixOS on ${target_hostname} at host ${target_host}."
yellow "generate_ssh_keys"
generate_ssh_keys
yellow "init_flakes"
init_flakes
yellow "prepare_git"
prepare_git
yellow "nixos_anywhere"
nixos_anywhere
