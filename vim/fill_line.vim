function! FillLine(arg)
    let l:max_line_length = &textwidth == 0 ? 79 : &textwidth
    let l:line = getline('.')
    const pat = escape(a:arg, '/\\.') . "\\+$"
    let l:line = substitute(l:line, pat, "", "")
    const lastc = l:line[-1:]
    const existing = lastc ==? a:arg
    let l:prefix = (lastc ==? ' ' || existing) ? '' : ' '
    let l:line_length = strlen(l:line) + len(l:prefix)
    if l:line_length < l:max_line_length
        let l:repeat = l:max_line_length - l:line_length
        let l:new_line = l:line . l:prefix . repeat(a:arg, l:repeat)
        let failed = setline(line('.'), l:new_line)
    else
        echo 'Line is too long!'
    endif
endfunction

command! -nargs=1 FillLine call FillLine('<args>')

" The following tests assume "FillLine =" is run on the first line and
" &textwidth is 78

" The line below this one should match the one below that
"
" ============================================================================

" The line below this one should match the one below that
" This is some text
" This is some text ==========================================================

" The line below this one should match the one below that
" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA =

" The line below this one should be too long
" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

" The line below this one (with trailing space) should match the one below that
" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 
" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA =

" The line below this one should match the one below that
" ====================================================================================
" ============================================================================

" The line below this one should be too long
" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=========
" ============================================================================

" The line below this one should match the one below that
" ========================
" ============================================================================
