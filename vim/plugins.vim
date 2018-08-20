" -------------------- Plugins --------------------
call plug#begin(g:vim_home. '/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'thinca/vim-localrc'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" TODO: Unused?/Fix?
Plug 'benekastah/neomake'
Plug 'critiqjo/lldb.nvim'
"Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'zchee/deoplete-jedi'
"Plug 'zchee/deoplete-clang'

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

