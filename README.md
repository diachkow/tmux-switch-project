# tmux-switch-project

A tmux plugin to quickly switch between project directories with favorites support.

## Features

- Fast project discovery using `fd` to find git repositories
- Favorites system - pin frequently used projects to the top
- Preview project contents in fzf
- Process detection - warns before killing running processes
- Configurable via tmux options

## Requirements

- [fd](https://github.com/sharkdp/fd) - fast file finder
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder
- tmux 3.0+

## Installation

### With TPM (recommended)

Add to your `tmux.conf`:

```tmux
set -g @plugin 'diachkow/tmux-switch-project'
```

Then press `prefix + I` to install.

### Manual

Clone the repo and add to your `tmux.conf`:

```tmux
run-shell /path/to/tmux-switch-project/switch-project.tmux
```

## Usage

Press `prefix + o` (default) to open the project switcher.

### Keybindings in fzf

| Key | Action |
|-----|--------|
| `Enter` | Select project |
| `ctrl-f` | Add to favorites |
| `ctrl-d` | Remove from favorites |

Favorites appear at the top of the list with a `★` prefix.

## Configuration

Add these to your `tmux.conf` before the plugin is loaded:

```tmux
# Key binding (default: o)
set -g @switch-project-key "o"

# Session name to use (default: work)
set -g @switch-project-session "work"

# Space-separated list of directories to search (default: $HOME/coding)
set -g @switch-project-dirs "$HOME/coding $HOME/.config"

# Path to favorites file (default: $HOME/.config/tmux/switch-project-favorites)
set -g @switch-project-favorites "$HOME/.config/tmux/switch-project-favorites"
```

## License

MIT
