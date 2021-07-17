" -------------------- Plugins --------------------

" Download vim-plug if it's not there
" Based on https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let s:plug_path = g:vim_home . '/autoload/plug.vim'
let s:plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
if empty(glob(s:plug_path))
    silent execute '!curl -fLo ' . s:plug_path . ' --create-dirs ' . s:plug_url
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(g:vim_home. '/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'thinca/vim-localrc'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-unimpaired'
Plug 'ap/vim-buftabline'
Plug 'airblade/vim-gitgutter'
Plug 'mzlogin/vim-markdown-toc'
Plug 'ziglang/zig.vim'
Plug 'nvie/vim-flake8'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Use local copy of vim-opendds, else download it
if isdirectory(expand('$LOCAL_VIM_OPENDDS'))
    Plug '~/oci/dds/vim-opendds'
else
    Plug 'iguessthislldo/vim-opendds'
endif

call plug#end()

" -------------------- Plugins Settings --------------------

" Airline
let g:airline_powerline_fonts = 1
let g:airline_theme="simple"

" Gitgutter
let g:gitgutter_max_signs = 1000

" Zig
let g:zig_fmt_autosave = 0

" Language Client
let g:LanguageClient_serverCommands = {
  \ 'cpp': ['clangd'],
  \ }
function LC_maps()
    if has_key(g:LanguageClient_serverCommands, &filetype)
        nnoremap <buffer> <silent> K :call LanguageClient#textDocument_hover()<cr>
        nnoremap <buffer> <silent> gd :call LanguageClient#textDocument_definition()<CR>
        nnoremap <buffer> <silent> gi :call LanguageClient#textDocument_implementation()<CR>
        nnoremap <buffer> <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
    endif
endfunction
autocmd FileType * call LC_maps()
