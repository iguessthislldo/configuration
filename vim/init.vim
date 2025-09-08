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

let init_files = [
    \ 'general', 'plugins', 'place', 'SwitchInclude', 'fill_line']

for i in init_files
    exec 'source ' . g:vim_home . '/' . i . '.vim'
endfor
