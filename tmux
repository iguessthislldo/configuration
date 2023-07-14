set-window-option -g mode-keys vi

# moving between panes with vim movement keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

set-option -g visual-bell on
set-option -g history-limit 5000
