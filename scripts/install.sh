#!/usr/bin/env bash
set -eo pipefail

persist_dir="/nix/persist"
config_repo="git@github.com:and-mel/nixconf.git"
secrets_repo="git@github.com:and-mel/nixconf-secrets.git"
target_hostname=""
main_device=""

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
  green "Adding GitHub to known hosts"
  ssh-keyscan -p 22 "github.com" >>~/.ssh/known_hosts || true
}

function init_flakes() {
  export GIT_AUTHOR_NAME="NixOS Installer"
  export GIT_AUTHOR_EMAIL="88601482+and-mel@users.noreply.github.com"
  export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
  timestamp=$(date +%s)
  green "Downloading flakes"
  export GIT_SSH_COMMAND="ssh -i ${temp}/id_ed25519_sk_rk"
  if ! retry git clone -q "${secrets_repo}" "${temp}/secrets"; then
    red "ERROR: Wrong Yubikey! Try using the right one."
    exit 1
  fi
  touch "${temp}/id_ed25519_gh"
  chmod 600 "${temp}/id_ed25519_gh"
  cd "${temp}/secrets"
  retry agenix -d id_ed25519.age -i identities/yubikey-personal.txt > ${temp}/id_ed25519_gh
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
  git add .
  git commit -m "[installer] ${timestamp}: Rekey for host ${target_hostname}" || true
  cd "${temp}"
  green "Generating hardware-configuration.nix"
  nixos-generate-config --root "${temp}" --no-filesystems
  rm -f "${temp}/nixos/hosts/${target_hostname}/hardware-configuration.nix"
  cp "${temp}/etc/nixos/hardware-configuration.nix" "${temp}/nixos/hosts/${target_hostname}/hardware-configuration.nix"
  cd "${temp}/nixos"
  git add .
  git commit -m "[installer] ${timestamp}: Add hardware configuration for host ${target_hostname}" || true
  cd "${temp}"
  green "Pre-installation finished."
}

function prepare_git() {
  yellow "Some destructive actions are about to occur!"
  yellow " - New decryption key and hardware configuration will be pushed to GitHub."
  yellow " - Disk will be erased and formatted"
  yellow " - Nix flake and secrets will be copied to disk."
  yellow " - NixOS will be installed."
  if ! yes_or_no "Do you want to continue?"; then
    red "Installation canceled by user"
    exit 0
  fi
  cd "${temp}/secrets"
  green "push secrets"
  git push -q
  cd "${temp}/nixos"
  green "nix flake update mysecrets"
  nix flake update mysecrets --extra-experimental-features "nix-command flakes"
  green "push nixos"
  git push -q
  cd "${temp}"
}

function copy_files() {
  green "Copying files"
  mkdir -p /mnt/nix/persist/etc/ssh
  cp "${temp}/id_ed25519" /mnt/nix/persist/etc/ssh/ssh_host_ed25519_key
  cp "${temp}/id_ed25519.pub" /mnt/nix/persist/etc/ssh/ssh_host_ed25519_key.pub
  # so agenix can decrypt
  mkdir -p /mnt/etc
  cp -r /mnt/nix/persist/etc/ssh /mnt/etc/ssh
  mkdir -p /mnt/home/andrei
  cp -r "${temp}/nixos" /mnt/home/andrei/nixos
  cp -r "${temp}/secrets" /mnt/home/andrei/secrets
}

function install_nixos() {
  green "Formatting disk"
  disko --mode destroy,format,mount -f "${temp}/nixos#${target_hostname}"
  copy_files
  green "Installing NixOS"
  nixos-install --flake "${temp}/nixos#${target_hostname}" --no-root-password
  green "NixOS is installed!"
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

echo "This script will install NixOS on ${target_hostname}."
yellow "generate_ssh_keys"
generate_ssh_keys
yellow "init_flakes"
init_flakes
yellow "prepare_git"
prepare_git
yellow "install_nixos"
install_nixos
