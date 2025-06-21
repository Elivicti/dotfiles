# A light blue style prompt with username, hostname, full path, return status, git branch, git dirty status, git remote status

local host_color="cyan"
if [ -n "$SSH_CLIENT" ]; then
  local host_color="red"
fi

# special symbols
local symbol_prompt="%{›%1G%}"
local symbol_git_dirty="%{⚡%2G%}"
local symbol_git_behind_remote="%{↓%1G%}"
local symbol_git_ahead_remote="%{↑%1G%}"
local symbol_git_diverged_remote="%{↕%1G%}"

local username="%{$fg_bold[${host_color}]%}%n"
local hostname="%{$fg_bold[${host_color}]%}%m"
local use_host="%{$fg_bold[grey]%}[%{$reset_color%}${username}%{$fg_bold[grey]%}@${hostname}%{$reset_color%}%{$fg_bold[grey]%}]%{$reset_color%}"
local working_dir="%{$fg_bold[blue]%}%10c%{$reset_color%}"

# local user_symbol="${return_status}%(!.#.›)%{$reset_color%}"
local return_status="%(?.%{$fg_bold[cyan]%}.%{$fg[red]%})"
local user_symbol='${return_status}%(!.#.${symbol_prompt})%{$reset_color%}'

local git_info='$(git_prompt_info)$(git_remote_status)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[red]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}) %{$fg[yellow]%}${symbol_git_dirty}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[red]%}) "
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}${symbol_git_behind_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}${symbol_git_ahead_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}${symbol_git_diverged_remote}%{$reset_color%}"

ZSH_THEME_TERM_TAB_TITLE_IDLE="%n@%m:%~"

PROMPT="${use_host} ${working_dir} ${git_info}${user_symbol} "
# RPROMPT=""
