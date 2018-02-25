" -------------------- Plugins --------------------
call plug#begin(g:vim_home. '/plugged')

Plug 'tpope/vim-sensible'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'benekastah/neomake'
Plug 'scrooloose/nerdtree'
Plug 'thinca/vim-localrc'
Plug 'tpope/vim-fugitive' " Git
Plug 'critiqjo/lldb.nvim'

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-jedi'
" Plug 'zchee/deoplete-clang'
Plug 'rust-lang/rust.vim'

" Trying out
Plug 'tpope/vim-commentary'

call plug#end()

" -------------------- Plugins Settings --------------------

set noautoindent

" Use deoplete.
let g:deoplete#enable_at_startup = 1
" Use smartcase.
let g:deoplete#enable_smart_case = 1

" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> deoplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS>  deoplete#smart_close_popup()."\<C-h>"

" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function() abort
  return deoplete#close_popup() . "\<CR>"
endfunction

" Airline
set t_Co=256
let g:airline_powerline_fonts = 1
let g:airline_theme="laederon"
