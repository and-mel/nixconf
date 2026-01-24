#!/usr/bin/env bash
set -eo pipefail

persist_dir="/nix/persist"
config_repo="git@github.com:and-mel/nixconf.git"
secrets_repo="git@github.com:and-mel/nixconf-secrets.git"
target_hostname=""

temp=$(mktemp -d)

function cleanup() {
  cat "${temp}/secrets/secrets.json"
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
  green "Generating SSH key from Yubikey"
  yellow "Please insert the Yubikey..."
  yellow "You will need to authorize with the Yubikey 3 times. Please don't remove the Yubikey."
  if ! ssh-keygen -K; then
    red "ERROR: Make sure you have your Yubikey inserted!"
    exit 1
  fi
  green "Generating host key"
  ssh-keygen -t ed25519 -N "" -f "${temp}/id_ed25519" -q -C ""
}

function init_flakes() {
  green "Downloading flakes"
  export GIT_SSH_COMMAND="ssh -i ${temp}/id_ed25519_sk_rk"
  if ! git clone -q "${secrets_repo}" "${temp}/secrets"; then
    red "ERROR: Wrong Yubikey! Try using the right one."
    exit 1
  fi
  touch "${temp}/id_ed25519_gh"
  chmod 600 "${temp}/id_ed25519_gh"
  cd "${temp}/secrets"
  agenix -d id_ed25519.age -i identities/yubikey-personal.txt > ${temp}/id_ed25519_gh
  yellow "You can remove the Yubikey"
  cp "${temp}/secrets/id_ed25519.pub" "${temp}/id_ed25519_gh.pub"
  export GIT_SSH_COMMAND="ssh -i ${temp}/id_ed25519_gh"
  git clone -q "${config_repo}" "${temp}/nixos"
  green "Validating host"
  host_in_flake="$(nix flake show "${temp}/nixos" --extra-experimental-features "nix-command flakes" --all-systems --json | yq ".nixosConfigurations | has(\"${target_hostname}\")" - )"
  echo "${host_in_flake}"
  if [ ${host_in_flake} != "true" ] || [ ! -d "${temp}/nixos/hosts/${target_hostname}" ]; then
    red "ERROR: Hostname ${target_hostname} doesn't exist in config flake or the hosts directory! Double-check the flake."
    exit 1
  fi
  green "Adding new ssh key to secrets.nix"
  yq -i ".systems.${target_hostname} = \"$(head -1 ${temp}/id_ed25519.pub | xargs)\"" "${temp}/secrets/secrets.json"
  agenix -r -i "${temp}/id_ed25519_gh"
  cd "${temp}"
  green "Generating hardware-configuration.nix"
  nixos-generate-config --root "${temp}" --no-filesystems
  rm -f "${temp}/nixos/hosts/${target_hostname}/hardware-configuration.nix"
  cp "${temp}/etc/nixos/hardware-configuration.nix" "${temp}/nixos/hosts/${target_hostname}/hardware-configuration.nix"
  cd "${temp}/nixos"
  git add .
  cd "${temp}"
}

# Validate required options
if [ -z "${target_hostname}" ]; then
	red "ERROR: -n is required"
	echo
	help_and_exit
fi

if [ "$(whoami)" != "root" ]; then
  red "ERROR: this script must run as root"
  exit 1
fi

cd "${temp}"

generate_ssh_keys
init_flakes
disko-install --write-efi-boot-entries --flake "${temp}/nixos#${target_hostname}"
