" GDB ------------------------------------------------------------------------

augroup igtd_gdb_ft
    autocmd!

    " Set filetype if it has an gdb ext
    autocmd BufNewFile,BufRead *.gdb setf gdb

    " how to comment
    autocmd FileType gdb setlocal commentstring=#\ %s
augroup END

" CMake ----------------------------------------------------------------------

" how to comment
augroup igtd_gdb_ft
    autocmd!

    autocmd FileType cmake setlocal commentstring=#\ %s
augroup END
