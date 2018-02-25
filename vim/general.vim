" Use Unix as the standard file type
set ffs=unix,dos,mac

" Tags
set tags=./tags;/

" NO NOT AUTOINDENT UNLESS ENTER IS PRESSED
autocmd BufReadPre,FileReadPre setlocal indentkeys=*<Return>

" Undo
set undofile
set undodir=~/cfg/vim/undo_dir

"Show Line Numbers
set number
set numberwidth=2

" Disable Mouse
set mouse=

" ================ Search ====================

" Highlight search results
set hlsearch

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Makes search act like search in modern browsers
set incsearch 

hi Folded ctermbg=58
"setlocal foldmethod=syntax

" =============================================

" Expand file search
set path+=**
set wildmenu

" Auto wrap left or right
set whichwrap+=<,>,h,l

" let &colorcolumn=join(range(81,999),",")
" Tab is 4 Spaces
set softtabstop=4 tabstop=4 shiftwidth=4 expandtab
