let g:is_msys = !empty($MSYS)

if g:is_msys
    set shellcmdflag=-c shellxquote= shellxescape=
endif

function! NativePath(path) abort
    if g:is_msys
        return systemlist(['cygpath', '--mixed', a:path])[0]
    else
        return a:path
    endif
endfunction

let g:vim_home = NativePath(fnamemodify(resolve(expand('<sfile>:p')), ':h'))

for init_file in sort(glob(g:vim_home . '/*.init.vim', 0, 1))
    exec 'source ' . init_file
endfor
