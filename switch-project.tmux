#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default option values
default_key="o"
default_session_name="work"
default_project_dirs="$HOME/coding"
default_favorites_file="$HOME/.config/tmux/switch-project-favorites"

# Get tmux option or return default
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

main() {
    local key=$(get_tmux_option "@switch-project-key" "$default_key")
    local session_name=$(get_tmux_option "@switch-project-session" "$default_session_name")
    local project_dirs=$(get_tmux_option "@switch-project-dirs" "$default_project_dirs")
    local favorites_file=$(get_tmux_option "@switch-project-favorites" "$default_favorites_file")

    # Bind the key to run the switch script in a popup
    tmux bind-key "$key" display-popup -E -w 80% -h 80% \
        "SESSION_NAME='$session_name' PROJECT_DIRS='$project_dirs' FAVORITES_FILE='$favorites_file' '$CURRENT_DIR/scripts/switch.sh'"
}

main
