
local host_color="green"
if [ -n "$SSH_CLIENT" ]; then
  local host_color="red"
fi

# special symbols
local symbol_lbracket="%{‹%1G%}"
local symbol_rbracket="%{›%1G%}"
local symbol_dot="%{●%1G%}"
local symbol_git_behind_remote="%{↓%1G%}"
local symbol_git_ahead_remote="%{↑%1G%}"
local symbol_git_diverged_remote="%{↕%1G%}"

local username="%{$fg[${host_color}]%}%n"
local hostname="%{$fg[${host_color}]%}%m"
local userhost="%B${username}@${hostname}%{$reset_color%}"
local user_symbol='%(?..%{$fg[red]%})%(!.#.$)%{$reset_color%}'
local working_dir="%B%{$fg[blue]%}%~%{$reset_color%}"

local git_info='$(git_prompt_info)$(git_remote_status)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}${symbol_lbracket}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${symbol_rbracket} %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}${symbol_dot}%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%}"

ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}${symbol_git_behind_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}${symbol_git_ahead_remote}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}${symbol_git_diverged_remote}%{$reset_color%}"

# ZSH_THEME_HG_PROMPT_PREFIX="$ZSH_THEME_GIT_PROMPT_PREFIX"
# ZSH_THEME_HG_PROMPT_SUFFIX="$ZSH_THEME_GIT_PROMPT_SUFFIX"
# ZSH_THEME_HG_PROMPT_DIRTY="$ZSH_THEME_GIT_PROMPT_DIRTY"
# ZSH_THEME_HG_PROMPT_CLEAN="$ZSH_THEME_GIT_PROMPT_CLEAN"
#
# ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}${symbol_lbracket}"
# ZSH_THEME_RUBY_PROMPT_SUFFIX="${symbol_rbracket} %{$reset_color%}"
#
# ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{$fg[green]%}‹"
# ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="› %{$reset_color%}"
# ZSH_THEME_VIRTUALENV_PREFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX"
# ZSH_THEME_VIRTUALENV_SUFFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX"

ZSH_THEME_TERM_TAB_TITLE_IDLE="%n@%m:%~"

PROMPT="${userhost}:${working_dir}${git_info}%B${user_symbol}%b "
