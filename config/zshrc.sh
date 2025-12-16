CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/..

# Instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export TERM="xterm-256color"

ZSH_DISABLE_COMPFIX=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH=$HOME/.oh-my-zsh

plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

source $ZSH/oh-my-zsh.sh 2>/dev/null

# Configure zsh-autosuggestions
# Accept suggestions with right arrow key
bindkey '^[[C' forward-word
# Accept suggestions with end key
bindkey '^[[F' autosuggest-accept
# Accept suggestions with ctrl+space
bindkey '^ ' autosuggest-accept
# Partial accept with right arrow (accept one word at a time)
bindkey '^[[1;5C' forward-word
# Make suggestions more visible
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,bold"
# Use both history and completion for suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Enable async suggestions for better performance
ZSH_AUTOSUGGEST_USE_ASYNC=true

# Auto-install and load history-substring-search plugin if oh-my-zsh is not available or plugin not loaded
if ! zle -l history-substring-search-up 2>/dev/null; then
    # Set up standalone plugin directory
    ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
    HISTORY_SUBSTRING_SEARCH_DIR="$ZSH_PLUGINS_DIR/zsh-history-substring-search"
    HISTORY_SUBSTRING_SEARCH_FILE="$HISTORY_SUBSTRING_SEARCH_DIR/zsh-history-substring-search.zsh"
    
    # Download plugin if it doesn't exist
    if [[ ! -f "$HISTORY_SUBSTRING_SEARCH_FILE" ]]; then
        echo "Installing zsh-history-substring-search plugin..."
        mkdir -p "$ZSH_PLUGINS_DIR"
        if command -v git >/dev/null 2>&1; then
            git clone https://github.com/zsh-users/zsh-history-substring-search.git "$HISTORY_SUBSTRING_SEARCH_DIR" 2>/dev/null || {
                echo "Warning: Failed to clone history-substring-search plugin"
            }
        else
            echo "Warning: git not found, cannot install history-substring-search plugin"
        fi
    fi
    
    # Load the plugin if it exists
    if [[ -f "$HISTORY_SUBSTRING_SEARCH_FILE" ]]; then
        source "$HISTORY_SUBSTRING_SEARCH_FILE"
        
        # Set up key bindings (try multiple key code formats for compatibility)
        bindkey '^[[A' history-substring-search-up 2>/dev/null
        bindkey '^[[B' history-substring-search-down 2>/dev/null
        bindkey '^[OA' history-substring-search-up 2>/dev/null
        bindkey '^[OB' history-substring-search-down 2>/dev/null
    fi
fi

# Auto-install and load zsh-autosuggestions plugin if oh-my-zsh is not available or plugin not loaded
if ! command -v _zsh_autosuggest_start >/dev/null 2>&1 && ! zle -l autosuggest-accept 2>/dev/null; then
    # Set up standalone plugin directory
    ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
    AUTOSUGGESTIONS_DIR="$ZSH_PLUGINS_DIR/zsh-autosuggestions"
    AUTOSUGGESTIONS_FILE="$AUTOSUGGESTIONS_DIR/zsh-autosuggestions.zsh"
    
    # Download plugin if it doesn't exist
    if [[ ! -f "$AUTOSUGGESTIONS_FILE" ]]; then
        echo "Installing zsh-autosuggestions plugin..."
        mkdir -p "$ZSH_PLUGINS_DIR"
        if command -v git >/dev/null 2>&1; then
            git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR" 2>/dev/null || {
                echo "Warning: Failed to clone zsh-autosuggestions plugin"
            }
        else
            echo "Warning: git not found, cannot install zsh-autosuggestions plugin"
        fi
    fi
    
    # Load the plugin if it exists
    if [[ -f "$AUTOSUGGESTIONS_FILE" ]]; then
        source "$AUTOSUGGESTIONS_FILE"
        
        # Configure autosuggestions
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,bold"  # Gray, bold text for suggestions
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # Use history and completion
        
        # Key bindings: Right arrow to accept suggestion
        bindkey '^[[C' forward-char  # Right arrow accepts suggestion (default behavior)
    fi
fi

source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/p10k.zsh
source $CONFIG_DIR/extras.sh
source $CONFIG_DIR/key_bindings.sh
add_to_path "${DOT_DIR}/custom_bins"

# for uv
if [ -d "$HOME/.local/bin" ]; then
  source $HOME/.local/bin/env
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if [ -d "$HOME/.cargo" ]; then
  . "$HOME/.cargo/env"
fi

if [ -d "$HOME/.pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if [ -d "$HOME/.local/bin/micromamba" ]; then
  export MAMBA_EXE="$HOME/.local/bin/micromamba"
  export MAMBA_ROOT_PREFIX="$HOME/micromamba"
  __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__mamba_setup"
  else
      alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
  fi
  unset __mamba_setup
fi

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

if command -v ask-sh &> /dev/null; then
  export ASK_SH_OPENAI_API_KEY=$(cat $HOME/.openai_api_key)
  export ASK_SH_OPENAI_MODEL=gpt-4o-mini
  eval "$(ask-sh --init)"
fi

cat $CONFIG_DIR/start.txt
