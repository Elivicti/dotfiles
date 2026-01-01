# A light blue style prompt with username, hostname, full path, return status, git branch, git dirty status, git remote status

local grey="%{$FG[250]%}"
local blue="%{$FG[033]%}"
local cyan="%{$FG[081]%}"

local host_color="${cyan}"
if [ -n "$SSH_CLIENT" ]; then
	local host_color="%{$fg[red]%}"
fi

# special symbols
local symbol_prompt="%{›%1G%}"
local symbol_prompt_nl="%{»%1G%}"
local symbol_git_dirty="%{⚡%2G%}"
local symbol_git_behind_remote="%{↓%1G%}"
local symbol_git_ahead_remote="%{↑%1G%}"
local symbol_git_diverged_remote="%{↕%1G%}"

local username="${host_color}%n"
local hostname="${host_color}%m"
local userhost="${grey}[${username}${grey}@${hostname}${grey}]%{$reset_color%}"
local working_dir="${blue}%10c%{$reset_color%}"

local return_status="%(?.%B${cyan}.%{$fg_bold[red]%})"
local user_symbol='${return_status}%(!.#.${symbol_prompt})%{$reset_color%}'
local user_symbol_nl='${return_status}%(!.#.${symbol_prompt_nl})%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[red]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}) %{$fg[yellow]%}${symbol_git_dirty}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[red]%}) "
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}${symbol_git_behind_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}${symbol_git_ahead_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}${symbol_git_diverged_remote}%{$reset_color%}"

ZSH_THEME_TERM_TAB_TITLE_IDLE="%n@%m:%~"

function set_prompt() {
	local path_length=${#${(%):-%~}}
	local git_info='$(git_prompt_info)$(git_remote_status)'

	if (( path_length > ${PROMPT_PATH_LIMIT:-60} )); then
		PROMPT="${userhost} ${working_dir} ${git_info}
${user_symbol_nl} "
	else
		PROMPT="${userhost} ${working_dir} ${git_info}${user_symbol} "
	fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt

set_prompt
