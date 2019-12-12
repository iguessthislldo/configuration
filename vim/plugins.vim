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
Plug 'airblade/vim-gitgutter'
Plug 'mzlogin/vim-markdown-toc'
Plug 'ziglang/zig.vim.git'

call plug#end()

" -------------------- Plugins Settings --------------------

set noautoindent

" Use deoplete.
"let g:deoplete#enable_at_startup = 1
" Use smartcase.
"let g:deoplete#enable_smart_case = 1

" <C-h>, <BS>: close popup and delete backword char.
"inoremap <expr><C-h> deoplete#smart_close_popup()."\<C-h>"
"inoremap <expr><BS>  deoplete#smart_close_popup()."\<C-h>"

" <CR>: close popup and save indent.
"inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
"function! s:my_cr_function() abort
"  return deoplete#close_popup() . "\<CR>"
"endfunction

" Airline
"set t_Co=256
let g:airline_powerline_fonts = 1
let g:airline_theme="simple"

let g:gitgutter_max_signs = 1000
