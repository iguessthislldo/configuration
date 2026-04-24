" Simple journal plugin
if exists('g:loaded_journal')
  finish
endif
let g:loaded_journal = 1

" Store the plugin directory
let g:journal_plugin_dir = fnamemodify(expand('<sfile>'), ':p:h:h')

command! Day call journal#open_today()
