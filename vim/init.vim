let g:vim_home = fnamemodify(resolve(expand('<sfile>:p')), ':h')

for i in ['general', 'plugins', 'place', 'SwitchInclude']
    exec 'source ' . g:vim_home . '/' . i . '.vim'
endfor
