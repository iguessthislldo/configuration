" GDB ------------------------------------------------------------------------
" Set filetype if it has an gdb ext
if exists("did_load_filetypes")
  finish
endif
augroup filetypedetect
  au! BufNewFile,BufRead *.gdb setf gdb
augroup END
" how to comment
autocmd FileType gdb setlocal commentstring=#\ %s

