" Tick Time
set updatetime=100

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Tags
set tags=./tags;/

" Undo
set undofile
let &undodir = g:vim_home . '/undo_dir'

"Show Line Numbers
set number
set numberwidth=2

" Update spl file if needed
" from https://vi.stackexchange.com/a/5052
for d in glob(g:vim_home . '/spell/*.add', 1, 1)
    if filereadable(d) && (!filereadable(d . '.spl') || getftime(d) > getftime(d . '.spl'))
        exec 'mkspell! ' . fnameescape(d)
    endif
endfor

set background=dark

set noautoindent

set hidden

" Display Encoding Errors as Hex
set display+=uhex

" Move to the next or previous line
set whichwrap+=<,>,h,l

" Mark the 100th char column in the buffer
let &colorcolumn=100

" Tab is 4 Spaces
set softtabstop=4 tabstop=4 shiftwidth=4 expandtab

" Expand file search
set path+=**
set wildmenu

" ================ Search ====================

" Highlight search results
set hlsearch

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Makes search act like search in modern browsers
set incsearch

" Folding
setlocal foldmethod=syntax
set nofoldenable

" ================ C/C++ ====================

" C Syntax
let c_gnu=1

" Do not indent case statments
set cinoptions=:0

" Do not indent public, private, etc in classes
set cinoptions+=g-1

" Highlight Trailing Space
let c_space_errors = 1

" ================ Key Combinations ====================

" Set Leader
let mapleader = ","

" Copy Paste from system clipboard
vnoremap <leader>y "+y
nnoremap <leader>p "+p

if !has('clipboard')
    echom "WARNING: Can not use clipboard! (Missing xclip?)"
endif

" Do not autoindent unless enter is pressed
augroup indent_on_enter
    autocmd!
    autocmd BufReadPre,FileReadPre * setlocal indentkeys=*<Return>
augroup END

" F12 Resync Syntax Highlighting
noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>
