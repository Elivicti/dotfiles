# A multiline prompt with username, hostname, full path, return status, git branch, git dirty status, git remote status

local return_status="%{$fg[red]%}%(?..⏎)%{$reset_color%}"

local host_color="cyan"
if [ -n "$SSH_CLIENT" ]; then
  local host_color="red"
fi

local username="%{$fg_bold[${host_color}]%}%n"
local hostname="%{$fg_bold[${host_color}]%}%m"
local use_host="%{$fg_bold[grey]%}[%{$reset_color%}${username}%{$fg_bold[grey]%}@${hostname}%{$reset_color%}%{$fg_bold[grey]%}]%{$reset_color%}"
local working_dir="%{$fg_bold[blue]%}%10c%{$reset_color%}"
local user_symbol='%{$fg_bold[cyan]%}%(!.#.›)%{$reset_color%}'

local git_='$(git_prompt_info)$(git_remote_status)'

PROMPT="${use_host} ${working_dir} ${git_}${user_symbol} "


RPROMPT='${return_status}%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[red]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}) %{$fg[yellow]%}⚡%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[red]%}) "
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}↓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}↑%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}↕%{$reset_color%}"

ZSH_THEME_TERM_TAB_TITLE_IDLE="%n@%m:%~"
