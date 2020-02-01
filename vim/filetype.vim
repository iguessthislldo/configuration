" GDB ------------------------------------------------------------------------

augroup igtd_gdb_ft
    autocmd!

    " Set filetype if it has an gdb ext
    autocmd BufNewFile,BufRead *.gdb setf gdb

    " how to comment
    autocmd FileType gdb setlocal commentstring=#\ %s
augroup END

" ACE/TAO --------------------------------------------------------------------

augroup igtd_ace_tao_files
    autocmd!

    " *.ypp are yacc files
    autocmd BufNewFile,BufRead *.ypp setf yacc

    " *.ll are lex files
    autocmd BufNewFile,BufRead *.ll setf lex

    " *.GNU are make
    autocmd BufNewFile,BufRead *.GNU setf make
augroup END

" CMake ----------------------------------------------------------------------

" how to comment
augroup igtd_gdb_ft
    autocmd!

    autocmd FileType cmake setlocal commentstring=#\ %s
augroup END
