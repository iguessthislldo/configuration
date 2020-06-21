command -range SwitchInclude
    \ <line1>,<line2>s/\(#\s*include\s\+\)<\([^<>]*\)>\(.*\)/\1%\2%\3/e
    \ | <line1>,<line2>s/\(#\s*include\s\+\)"\([^"]*\)"\(.*\)/\1<\2>\3/e
    \ | <line1>,<line2>s/\(#\s*include\s\+\)%\([^%]*\)%\(.*\)/\1"\2"\3/e
    \ | noh
" #include "abc"
" # include "abc" // abc
" #include <abc>
" # include <abc> // abc
