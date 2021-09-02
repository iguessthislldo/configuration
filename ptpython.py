__all__ = ["configure"]

def configure(repl):
    repl.vi_mode = True
    # Use up and down to go through history
    repl.enable_history_search = True
    # Conflicts with enable_history_search if True. If False, must use tab to
    # complete.
    repl.complete_while_typing = False
