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
Plug 'neovim/nvim-lspconfig'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Use local copy of vim-opendds, else download it
if isdirectory(expand('$LOCAL_VIM_OPENDDS'))
    Plug expand('$LOCAL_VIM_OPENDDS')
else
    Plug 'iguessthislldo/vim-opendds'
endif

call plug#end()

" -------------------- Plugins Settings --------------------

" Airline
let g:airline_powerline_fonts = 1
let g:airline_theme="simple"

" Gitgutter
let g:gitgutter_max_signs = 10000

" Zig
let g:zig_fmt_autosave = 0

" lspconfig
lua << EOF
local lspconfig = require'lspconfig'
local configs = require'lspconfig/configs'
local util = require 'lspconfig/util'

-- C/C++
lspconfig.clangd.setup{
    root_dir = util.root_pattern('compile_commands.json'),
}

-- Perl
lspconfig.perlls.setup{}

-- IDL
if not lspconfig.bridle then
    configs.bridle = {
        default_config = {
            cmd = {'bridle', 'lang-server'};
            filetypes = {'opendds_idl'};
            root_dir = function(fname)
                return lspconfig.util.find_git_ancestor(fname);
            end;
            settings = {};
        }
    }
end
lspconfig.bridle.setup{}
EOF
