" GDB ------------------------------------------------------------------------
" Set filetype if it has an gdb ext
augroup gdb_ft
  au! BufNewFile,BufRead *.gdb setf gdb
augroup END
" how to comment
autocmd FileType gdb setlocal commentstring=#\ %s

" tao_idl flex/bison ---------------------------------------------------------
" *.ypp are yacc files
augroup tao_idl_ft
  au! BufNewFile,BufRead *.ypp setf yacc
  au! BufNewFile,BufRead *.ll setf lex
augroup END

augroup ace_makefiles
  au! BufNewFile,BufRead *.GNU setf make
augroup END
