{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-y";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    historyLimit = 10000;
    aggressiveResize = true;
    terminal = "screen-256color";


    # The configurations below aren't available natively, so we use extraConfig.
    extraConfig = ''
        # Ensure window index numbers get reordered on delete.
        set-option -g renumber-windows on

        # colors
        # set -g default-terminal "''${TERM}"

        # Enable undercurl
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'

        # Enable undercurl colors
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

        # vi mode
        set-window-option -g mode-keys vi
        bind-key -T copy-mode-vi v send -X begin-selection
        bind-key -T copy-mode-vi V send -X select-line

        # macOS-specific commands
        if-shell "[ -x $(command -v sw_vers) ]" {
          bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'pbcopy'
        }

        # Linux-specific commands
        if-shell "[ ! -x $(command -v sw_vers) ]" {
          bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
        }

        # Allow tmux to set the terminal title
        set -g set-titles on

        # Monitor window activity to display in the status bar
        setw -g monitor-activity on

        # A bell in another window should cause a bell in the current window
        set -g bell-action any

        # Don't show distracting notifications
        set -g visual-bell off
        set -g visual-activity off

        # Focus events enabled for terminals that support them
        set -g focus-events on

        # Useful when using sharing a session with different size terminals
        setw -g aggressive-resize on

        # don't detach tmux when killing a session
        set -g detach-on-destroy off

        # address vim mode switching delay (http://superuser.com/a/252717/65504)
        set -s escape-time 0


        # STATUS BAR

        # Status line customisation
        set-option -g status-left-length 100
        set-option -g status-right-length 100
        set-option -g status-left " #{session_name}  "
        set-option -g status-right "#{pane_title} "
        set-option -g status-style "fg=#7C7D83 bg=#242631"
        set-option -g window-status-format "#{window_index}:#{pane_current_command}#{window_flags} "
        set-option -g window-status-current-format "#{window_index}:#{pane_current_command}#{window_flags} "
        set-option -g window-status-current-style "fg=#E9E9EA"
        set-option -g window-status-activity-style none


        # KEYBINDS

        # -r means that the bind can repeat without entering prefix again
        # -n means that the bind doesn't use the prefix

        # Set the prefix to Ctrl+Space
        #set -g prefix C-Space

        # Send prefix to a nested tmux session by doubling the prefix
        #bind C-Space send-prefix

        # 'PREFIX r' to reload of the config file
        #unbind r
        #bind r source-file ~/.tmux.conf\; display-message '~/.tmux.conf reloaded'

        # Allow holding Ctrl when using using prefix+p/n for switching windows
        bind C-p previous-window
        bind C-n next-window

        # Move around panes like in vim
        bind -r h select-pane -L
        bind -r j select-pane -D
        bind -r k select-pane -U
        bind -r l select-pane -R
        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+

        # Smart pane switching with awareness of vim splits
        is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
        bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
        bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
        bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
        bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

        # Switch between previous and next windows with repeatable
        bind -r n next-window
        bind -r p previous-window

        # Move the current window to the next window or previous window position
        bind -r N run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) + 1)"
        bind -r P run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) - 1)"

        # Switch between two most recently used windows
        bind Space last-window

        # Switch between two most recently used sessions
        bind ^ switch-client -l

        # split with path
        bind % split-window -h -c "#{pane_current_path}"
        bind '"' split-window -v -c "#{pane_current_path}"

        # Change the path for newly created windows
        bind c new-window -c "#{pane_current_path}"

        # Setup 'v' to begin selection as in Vim
        #if-shell -b '[ "$(echo "$TMUX_VERSION >= 2.4" | bc)" = 1 ]' \
            #'bind-key -T copy-mode-vi v send-keys -X begin-selection;'

        #bind y run -b "tmux show-buffer | xclip -selection clipboard"\; display-message "Copied tmux buffer to system clipboard"

        bind-key -r F new-window t
        bind-key -r D run-shell "t ~/code/tobmoeller/dotfiles"
    '';
  };
}
