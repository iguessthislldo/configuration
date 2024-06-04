{ pkgs ? import <nixpkgs> {} }:

{
    inherit (pkgs)
        neovim
        git
    ;
}
