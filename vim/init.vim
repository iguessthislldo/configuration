let g:vim_home = fnamemodify(resolve(expand('<sfile>:p')), ':h')

let init_files = [
    \ 'general', 'plugins', 'place', 'SwitchInclude', 'fill_line']

for i in init_files
    exec 'source ' . g:vim_home . '/' . i . '.vim'
endfor
