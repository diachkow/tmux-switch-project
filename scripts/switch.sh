#!/usr/bin/env bash
# Switch tmux session to a different project directory

# These can be overridden via environment variables (set by the plugin)
SESSION_NAME="${SESSION_NAME:-work}"
FAVORITES_FILE="${FAVORITES_FILE:-$HOME/.config/tmux/switch-project-favorites}"

# Convert space-separated string to array
IFS=' ' read -ra PROJECT_DIRS_ARRAY <<< "${PROJECT_DIRS:-$HOME/coding}"

# Build the list of projects
get_project_list() {
    # Show favorites first (marked with a star)
    if [ -f "$FAVORITES_FILE" ]; then
        while IFS= read -r fav; do
            [ -d "$fav" ] && echo "★ $fav"
        done < "$FAVORITES_FILE"
    fi
    # Then show all git repos
    for dir in "${PROJECT_DIRS_ARRAY[@]}"; do
        [ -d "$dir" ] && fd --type d --hidden --no-ignore "^\.git$" "$dir" --max-depth 5 \
            --exclude node_modules \
            --exclude .venv \
            --exclude venv \
            --exclude .cache \
            --exclude vendor \
            --exclude .npm \
            --exclude .cargo \
            --exclude .rustup \
            --exclude go/pkg \
            2>/dev/null
    done | xargs -I{} dirname {} | sort -u
}

# Export for use in fzf reload
export FAVORITES_FILE
export PROJECT_DIRS

SELECTED_DIR=$(get_project_list | fzf \
    --preview 'ls -la ${1#★ }' \
    --preview-window=right:30% \
    --height=100% \
    --reverse \
    --bind "ctrl-f:execute-silent(echo {} | sed 's/^★ //' >> \"$FAVORITES_FILE\" && sort -u -o \"$FAVORITES_FILE\" \"$FAVORITES_FILE\")+reload(
        if [ -f \"$FAVORITES_FILE\" ]; then
            while IFS= read -r fav; do
                [ -d \"\$fav\" ] && echo \"★ \$fav\"
            done < \"$FAVORITES_FILE\"
        fi
        for dir in $PROJECT_DIRS; do
            [ -d \"\$dir\" ] && fd --type d --hidden --no-ignore '^\.git$' \"\$dir\" --max-depth 5 \
                --exclude node_modules --exclude .venv --exclude venv --exclude .cache \
                --exclude vendor --exclude .npm --exclude .cargo --exclude .rustup --exclude go/pkg 2>/dev/null
        done | xargs -I{} dirname {} | sort -u
    )" \
    --bind "ctrl-d:execute-silent([ -f \"$FAVORITES_FILE\" ] && grep -v \"^\$(echo {} | sed 's/^★ //')$\" \"$FAVORITES_FILE\" > \"$FAVORITES_FILE.tmp\" && mv \"$FAVORITES_FILE.tmp\" \"$FAVORITES_FILE\")+reload(
        if [ -f \"$FAVORITES_FILE\" ]; then
            while IFS= read -r fav; do
                [ -d \"\$fav\" ] && echo \"★ \$fav\"
            done < \"$FAVORITES_FILE\"
        fi
        for dir in $PROJECT_DIRS; do
            [ -d \"\$dir\" ] && fd --type d --hidden --no-ignore '^\.git$' \"\$dir\" --max-depth 5 \
                --exclude node_modules --exclude .venv --exclude venv --exclude .cache \
                --exclude vendor --exclude .npm --exclude .cargo --exclude .rustup --exclude go/pkg 2>/dev/null
        done | xargs -I{} dirname {} | sort -u
    )" \
    --header 'ctrl-f: add favorite | ctrl-d: remove favorite' \
    | sed 's/^★ //')

if [ -z "$SELECTED_DIR" ]; then
    exit 0
fi

# Check if session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Session doesn't exist, create new one
    tmux new-session -d -s "$SESSION_NAME" -c "$SELECTED_DIR" -n nvim
    tmux new-window -t "$SESSION_NAME":1 -c "$SELECTED_DIR" -n test
    tmux new-window -t "$SESSION_NAME":2 -c "$SELECTED_DIR" -n root
    tmux switch-client -t "$SESSION_NAME"
    exit 0
fi

# Session exists, check for running processes (non-shell processes)
RUNNING_PROCESSES=""

for WINDOW_INDEX in 0 1 2; do
    # Get pane PIDs for this window
    PANE_PIDS=$(tmux list-panes -t "$SESSION_NAME:$WINDOW_INDEX" -F "#{pane_pid}" 2>/dev/null || true)
    
    for PANE_PID in $PANE_PIDS; do
        if [ -n "$PANE_PID" ] && [ "$PANE_PID" != "-1" ]; then
            # Get child processes (not the shell itself, but what's running in it)
            CHILDREN=$(pgrep -P "$PANE_PID" 2>/dev/null || true)
            
            if [ -n "$CHILDREN" ]; then
                for CHILD_PID in $CHILDREN; do
                    # Skip zsh/bash shells themselves
                    COMM=$(ps -o comm= -p "$CHILD_PID" 2>/dev/null || true)
                    if [ -n "$COMM" ] && [[ "$COMM" != "zsh" ]] && [[ "$COMM" != "bash" ]] && [[ "$COMM" != "-zsh" ]] && [[ "$COMM" != "-bash" ]]; then
                        PROCESS_INFO=$(ps -o pid=,comm= -p "$CHILD_PID" 2>/dev/null)
                        if [ -n "$PROCESS_INFO" ]; then
                            RUNNING_PROCESSES="${RUNNING_PROCESSES}${PROCESS_INFO}"$'\n'
                        fi
                    fi
                done
            fi
        fi
    done
done

# If there are running processes, ask for confirmation
if [ -n "$RUNNING_PROCESSES" ]; then
    echo "Running processes in session '$SESSION_NAME':"
    echo "$RUNNING_PROCESSES" | sort | uniq
    echo ""
    read -p "Kill these processes and switch to '$SELECTED_DIR'? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        sleep 1
        exit 0
    fi
fi

# Kill the old session and create a new one
# We need to do this carefully since we might be inside the session

# Create the new session first (with a temp name)
tmux new-session -d -s "${SESSION_NAME}_new" -c "$SELECTED_DIR" -n nvim
tmux new-window -t "${SESSION_NAME}_new":1 -c "$SELECTED_DIR" -n test
tmux new-window -t "${SESSION_NAME}_new":2 -c "$SELECTED_DIR" -n root
tmux select-window -t "${SESSION_NAME}_new":0

# Switch to the new session, then kill the old one, then rename
tmux switch-client -t "${SESSION_NAME}_new"
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
tmux rename-session -t "${SESSION_NAME}_new" "$SESSION_NAME"
