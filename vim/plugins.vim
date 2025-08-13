" Plugins ====================================================================

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
" Plug 'neovim/nvim-lspconfig'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'habamax/vim-rst'
Plug 'scottmckendry/cyberdream.nvim'
Plug 'folke/which-key.nvim'

" Use local copy of vim-opendds, else download it
if isdirectory(expand('$LOCAL_VIM_OPENDDS'))
    Plug expand('$LOCAL_VIM_OPENDDS')
else
    Plug 'iguessthislldo/vim-opendds'
endif

call plug#end()

set completeopt=menu,menuone,noselect

" Plugins Settings ===========================================================

" Airline --------------------------------------------------------------------
let g:airline_powerline_fonts = 1
let g:airline_theme="simple"

" Gitgutter ------------------------------------------------------------------
let g:gitgutter_max_signs = 10000
let g:gitgutter_preview_win_floating = 1
let g:gitgutter_floating_window_options = {
      \ 'relative': 'cursor',
      \ 'row': 1,
      \ 'col': 0,
      \ 'width': 64,
      \ 'height': &previewheight,
      \ 'style': 'minimal',
      \ 'border': 'rounded'
      \ }

" Zig ------------------------------------------------------------------------
let g:zig_fmt_autosave = 0

" LSP ------------------------------------------------------------------------
" TODO
lua << EOF
-- local lspconfig = require'lspconfig'
-- local configs = require'lspconfig/configs'
-- local util = require 'lspconfig/util'
--
-- -- C/C++
-- lspconfig.clangd.setup{
--     root_dir = util.root_pattern('compile_commands.json'),
-- }
--
-- -- Perl
-- lspconfig.perlls.setup{}
EOF

" cyberdream -----------------------------------------------------------------
lua << EOF
require("cyberdream").setup({
    -- Enable transparent background
    transparent = false,

    -- Reduce the overall saturation of colours for a more muted look
    saturation = 0.9, -- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default)

    -- Enable italics comments
    italic_comments = true,

    -- Apply a modern borderless look to pickers like Telescope, Snacks Picker & Fzf-Lua
    borderless_pickers = true,
})
vim.cmd("colorscheme cyberdream")
EOF
