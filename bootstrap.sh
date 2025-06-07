#!/bin/bash

script=$(cd `dirname $0`; pwd)
distro=$(cat /etc/issue | head -n1 | awk '{print $1}')
username=$(whoami)
eval HOME="~"

function backup_old() {
	if [ -L "$1" ]; then
		rm "$1"
		return 0
	fi

	if [ ! -e "$1" ]; then
		return 0
	fi

	datetime=$(date +"%Y%m%d_%H%M%S")

	# either file or directory
	mv "$1" "$1.bak-$datetime"
}

function link_theme() {
	theme_name="$1"
	theme="${script}/.oh-my-zsh/custom/themes/${theme_name}.zsh-theme"

	if [ ! -f "$theme" ]; then
		echo "Invalid theme: \"${theme_name}\", using default theme" >&2
		theme_name="ubuntu-bash"
		theme="${script}/.oh-my-zsh/custom/themes/ubuntu-bash.zsh-theme"
	fi
	echo "Using theme: ${theme_name}"

	THEME_DIR="$ZSH/custom/themes"

	if [ ! -d "$THEME_DIR" ]; then
		echo "Failed to set theme: $THEME_DIR is not a directory" >&2
		return 1
	fi

	theme_link="$ZSH/custom/themes/custom-theme.zsh-theme"
	# if a symlink already exists, delete it
	backup_old "$theme_link"
	ln -s "$theme" "$theme_link"

	return 0
}

function link_configs() {
	if [ ! -d "$HOME/.config" ]; then
		mkdir -p "$HOME/.config"
	fi

	echo "Setting up configs:"

	for conf in ${script}/.config/*; do
		conf_name="${conf##*/}"
		conf_target="$HOME/.config/${conf_name}"

		backup_old "$conf_target"

		echo "  $conf_name -> $conf_target"
		ln -s "${conf}" "${conf_target}"
	done
}

function link_rc() {
	echo "Setting up shell rc:"

	zshrc_target="$HOME/.zshrc"
	backup_old "$zshrc_target"

	echo "  .zshrc -> $zshrc_target"
	ln -s "$script/.zshrc" "$zshrc_target"
	
	userenv="$script/user-env/$1.sh"
	if [ ! -f "$userenv" ]; then
		echo "  User-env: \"$userenv\" is not a file, skipping" >&2
		return 1
	fi
	userenv_target="$HOME/.user-env.sh"
	backup_old "$userenv_target"

	echo "  $1.sh -> $userenv_target"
	ln -s "$userenv" "$userenv_target"
}

function link_ssh_keys() {
	echo "Linking ssh keys:"

	if [ ! -d "$HOME/.ssh/" ]; then
		mkdir -p "$HOME/.ssh"
	fi

	pvt_key=".ssh/id_rsa"
	pub_key=".ssh/id_rsa.pub"

	echo "  $pub_key -> $HOME/$pub_key"
	backup_old "$HOME/$pub_key"
	ln -s "$script/$pub_key" "$HOME/$pub_key"

	output=$(bash "$script/ssh_key.sh" -d)
	result=$?
	if [ $result -ne 0 ]; then
		echo "  $output" >&2
		echo "  Skipped linking private key" >&2
		return $result
	fi

	echo -e "\r  $pvt_key -> $HOME/$pvt_key"
	backup_old "$HOME/$pvt_key"
	ln -s "$script/$pvt_key" "$HOME/$pvt_key"
}

echo "Setting up configurations for ${username}"
echo "Distro: ${distro}"

# use ubuntu's config as default
theme="ubuntu-bash"
rc_env="ubuntu"

# distro specific configs
if [ "$distro"x == "Arch"x ]; then
	theme="arch-zsh"
	rc_env="arch"
fi

link_rc    "$rc_env"
link_theme "$theme"
link_configs
link_ssh_keys
