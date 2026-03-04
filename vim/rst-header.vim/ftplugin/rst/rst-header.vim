" rst-header.vim - Functions for manipulating reStructuredText headers

" RST headers use adornment characters. This defines the hierarchy (top to bottom):
let g:rst_header_hierarchy = get(g:, 'rst_header_hierarchy', ['#', '*', '=', '-', '^', '"', '~'])

" Characters that use overlines (both over and under)
let g:rst_header_overlined = get(g:, 'rst_header_overlined', ['#', '*'])

" Pattern to match a line that is purely adornment (at least 3 chars of the same type)
let s:adornment_pattern = '^\([#*=\-^"~`+]\)\1\{2,}$'

" Check if a line is an adornment line
function! s:IsAdornment(line)
    return a:line =~# s:adornment_pattern
endfunction

" Get the adornment character from a line
function! s:GetAdornmentChar(line)
    if s:IsAdornment(a:line)
        return a:line[0]
    endif
    return ''
endfunction

" Create an adornment line of the given character and length
function! s:MakeAdornment(char, length)
    return repeat(a:char, a:length)
endfunction

" Get the display width of text (handles multibyte)
function! s:TextWidth(text)
    return strdisplaywidth(a:text)
endfunction

" Find the index of a character in the hierarchy (-1 if not found)
function! s:HierarchyIndex(char)
    return index(g:rst_header_hierarchy, a:char)
endfunction

" Get the character at a hierarchy level (clamped to valid range)
function! s:HierarchyChar(index)
    let l:idx = a:index
    if l:idx < 0
        let l:idx = 0
    elseif l:idx >= len(g:rst_header_hierarchy)
        let l:idx = len(g:rst_header_hierarchy) - 1
    endif
    return g:rst_header_hierarchy[l:idx]
endfunction

" Check if a character uses overlines
function! s:NeedsOverline(char)
    return index(g:rst_header_overlined, a:char) >= 0
endfunction

" Replace a range of lines with new output (handles different line counts)
function! s:ReplaceLines(first, last, output)
    let l:old_count = a:last - a:first + 1
    let l:new_count = len(a:output)
    if l:new_count <= l:old_count
        call setline(a:first, a:output)
        if l:new_count < l:old_count
            execute (a:first + l:new_count) . ',' . a:last . 'delete _'
        endif
    else
        call setline(a:first, a:output[0:l:old_count-1])
        call append(a:last, a:output[l:old_count:])
    endif
endfunction

" Set header to a specific character level
" Returns: {'output': list of output lines, 'consumed': lines consumed from input}
function! s:SetHeaderToChar(lines, start_idx, target_char)
    let l:line = a:lines[a:start_idx]

    " Check for overline + title + underline pattern (existing overlined header)
    if s:IsAdornment(l:line) && a:start_idx + 2 < len(a:lines)
        let l:char = s:GetAdornmentChar(l:line)
        let l:title = a:lines[a:start_idx + 1]
        let l:underline = a:lines[a:start_idx + 2]

        if s:IsAdornment(l:underline) && s:GetAdornmentChar(l:underline) ==# l:char
            let l:width = s:TextWidth(l:title)
            let l:adorn = s:MakeAdornment(a:target_char, l:width)
            if s:NeedsOverline(a:target_char)
                return {'output': [l:adorn, l:title, l:adorn], 'consumed': 3}
            else
                return {'output': [l:title, l:adorn], 'consumed': 3}
            endif
        endif
    endif

    " Check for title + underline pattern (existing underlined header)
    if !s:IsAdornment(l:line) && l:line =~# '\S' && a:start_idx + 1 < len(a:lines)
        let l:title = l:line
        let l:underline = a:lines[a:start_idx + 1]

        if s:IsAdornment(l:underline)
            let l:width = s:TextWidth(l:title)
            let l:adorn = s:MakeAdornment(a:target_char, l:width)
            if s:NeedsOverline(a:target_char)
                return {'output': [l:adorn, l:title, l:adorn], 'consumed': 2}
            else
                return {'output': [l:title, l:adorn], 'consumed': 2}
            endif
        endif
    endif

    " Plain text line - convert to header
    if l:line =~# '\S'
        let l:width = s:TextWidth(l:line)
        let l:adorn = s:MakeAdornment(a:target_char, l:width)
        if s:NeedsOverline(a:target_char)
            return {'output': [l:adorn, l:line, l:adorn], 'consumed': 1}
        else
            return {'output': [l:line, l:adorn], 'consumed': 1}
        endif
    endif

    " Empty/whitespace line, pass through unchanged
    return {'output': [l:line], 'consumed': 1}
endfunction

" Process lines and shift headers
" Returns: {'output': list of output lines, 'consumed': lines consumed from input}
function! s:ProcessHeader(lines, start_idx, direction)
    let l:line = a:lines[a:start_idx]

    " Check for overline + title + underline pattern
    if s:IsAdornment(l:line) && a:start_idx + 2 < len(a:lines)
        let l:char = s:GetAdornmentChar(l:line)
        let l:title = a:lines[a:start_idx + 1]
        let l:underline = a:lines[a:start_idx + 2]

        if s:IsAdornment(l:underline) && s:GetAdornmentChar(l:underline) ==# l:char
            " This is an overlined header
            let l:new_idx = s:HierarchyIndex(l:char) + a:direction
            let l:new_char = s:HierarchyChar(l:new_idx)
            let l:width = s:TextWidth(l:title)
            let l:adorn = s:MakeAdornment(l:new_char, l:width)

            if s:NeedsOverline(l:new_char)
                " Keep overline
                return {'output': [l:adorn, l:title, l:adorn], 'consumed': 3}
            else
                " Remove overline
                return {'output': [l:title, l:adorn], 'consumed': 3}
            endif
        endif
    endif

    " Check for title + underline pattern (no overline)
    " Title must be non-empty and not just whitespace
    if !s:IsAdornment(l:line) && l:line =~# '\S' && a:start_idx + 1 < len(a:lines)
        let l:title = l:line
        let l:underline = a:lines[a:start_idx + 1]

        if s:IsAdornment(l:underline)
            let l:char = s:GetAdornmentChar(l:underline)
            let l:new_idx = s:HierarchyIndex(l:char) + a:direction
            let l:new_char = s:HierarchyChar(l:new_idx)
            let l:width = s:TextWidth(l:title)
            let l:adorn = s:MakeAdornment(l:new_char, l:width)

            if s:NeedsOverline(l:new_char)
                " Add overline
                return {'output': [l:adorn, l:title, l:adorn], 'consumed': 2}
            else
                " No overline needed
                return {'output': [l:title, l:adorn], 'consumed': 2}
            endif
        endif
    endif

    " Not a header, pass through unchanged
    return {'output': [l:line], 'consumed': 1}
endfunction

" Check if argument is a valid header character
function! s:IsHeaderChar(arg)
    return index(g:rst_header_hierarchy, a:arg) >= 0
endfunction

" Check if lines contain any header
function! s:ContainsHeader(lines)
    let l:i = 0
    while l:i < len(a:lines)
        let l:line = a:lines[l:i]
        " Check for overlined header
        if s:IsAdornment(l:line) && l:i + 2 < len(a:lines)
            let l:char = s:GetAdornmentChar(l:line)
            let l:underline = a:lines[l:i + 2]
            if s:IsAdornment(l:underline) && s:GetAdornmentChar(l:underline) ==# l:char
                return 1
            endif
        endif
        " Check for underlined header
        if !s:IsAdornment(l:line) && l:line =~# '\S' && l:i + 1 < len(a:lines)
            if s:IsAdornment(a:lines[l:i + 1])
                return 1
            endif
        endif
        let l:i += 1
    endwhile
    return 0
endfunction

" Get the current header character from lines (first header found)
function! s:GetCurrentHeaderChar(lines)
    let l:i = 0
    while l:i < len(a:lines)
        let l:line = a:lines[l:i]
        if s:IsAdornment(l:line) && l:i + 2 < len(a:lines)
            let l:char = s:GetAdornmentChar(l:line)
            let l:underline = a:lines[l:i + 2]
            if s:IsAdornment(l:underline) && s:GetAdornmentChar(l:underline) ==# l:char
                return l:char
            endif
        endif
        if !s:IsAdornment(l:line) && l:line =~# '\S' && l:i + 1 < len(a:lines)
            if s:IsAdornment(a:lines[l:i + 1])
                return s:GetAdornmentChar(a:lines[l:i + 1])
            endif
        endif
        let l:i += 1
    endwhile
    return ''
endfunction

" Main function: process a range of lines and shift headers
" arg: 'up', 'down', 'fix', or a header character like '=' or '*'
" Append '!' for silent mode (no messages when nothing changes), e.g. 'fix!'
function! RstHeader(arg) range
    " Check for silent mode (trailing !)
    let l:silent = a:arg =~# '!$'
    let l:arg = substitute(a:arg, '!$', '', '')

    let l:lines = getline(a:firstline, a:lastline)
    let l:output = []
    let l:i = 0
    let l:has_header = s:ContainsHeader(l:lines)
    let l:current_char = s:GetCurrentHeaderChar(l:lines)

    " Check if arg is a specific header character
    if s:IsHeaderChar(l:arg)
        while l:i < len(l:lines)
            let l:result = s:SetHeaderToChar(l:lines, l:i, l:arg)
            call extend(l:output, l:result.output)
            let l:i += l:result.consumed
        endwhile
    elseif l:arg ==? 'fix'
        if !l:has_header
            if !l:silent
                echo "No header found to fix"
            endif
            return
        endif
        while l:i < len(l:lines)
            let l:result = s:FixHeader(l:lines, l:i)
            call extend(l:output, l:result.output)
            let l:i += l:result.consumed
        endwhile
    else
        " Determine direction for up/down
        let l:direction = 0
        if l:arg ==? 'up'
            let l:direction = -1
        elseif l:arg ==? 'down'
            let l:direction = 1
        else
            echoerr "RstHeader: argument must be 'up', 'down', 'fix', or a header char (" . join(g:rst_header_hierarchy, ' ') . ")"
            return
        endif

        if !l:has_header
            if !l:silent
                echo "No header found"
            endif
            return
        endif

        " Check if already at limit
        if l:current_char != ''
            let l:idx = s:HierarchyIndex(l:current_char)
            if l:direction == -1 && l:idx == 0
                if !l:silent
                    echo "Already at highest level (" . l:current_char . ")"
                endif
                return
            elseif l:direction == 1 && l:idx == len(g:rst_header_hierarchy) - 1
                if !l:silent
                    echo "Already at lowest level (" . l:current_char . ")"
                endif
                return
            endif
        endif

        while l:i < len(l:lines)
            let l:result = s:ProcessHeader(l:lines, l:i, l:direction)
            call extend(l:output, l:result.output)
            let l:i += l:result.consumed
        endwhile
    endif

    " Check if anything changed
    if l:lines == l:output
        if !l:silent
            if l:arg ==? 'fix'
                echo "Header lengths already correct"
            elseif s:IsHeaderChar(l:arg)
                echo "Already at level '" . l:arg . "'"
            else
                echo "No changes needed"
            endif
        endif
        return
    endif

    call s:ReplaceLines(a:firstline, a:lastline, l:output)
endfunction

" Fix header length without changing level
" Returns: {'output': list of output lines, 'consumed': lines consumed from input}
function! s:FixHeader(lines, start_idx)
    let l:line = a:lines[a:start_idx]

    " Check for overline + title + underline
    if s:IsAdornment(l:line) && a:start_idx + 2 < len(a:lines)
        let l:char = s:GetAdornmentChar(l:line)
        let l:title = a:lines[a:start_idx + 1]
        let l:underline = a:lines[a:start_idx + 2]

        if s:IsAdornment(l:underline) && s:GetAdornmentChar(l:underline) ==# l:char
            let l:width = s:TextWidth(l:title)
            let l:adorn = s:MakeAdornment(l:char, l:width)
            return {'output': [l:adorn, l:title, l:adorn], 'consumed': 3}
        endif
    endif

    " Check for title + underline
    if !s:IsAdornment(l:line) && l:line =~# '\S' && a:start_idx + 1 < len(a:lines)
        let l:underline = a:lines[a:start_idx + 1]
        if s:IsAdornment(l:underline)
            let l:width = s:TextWidth(l:line)
            let l:char = s:GetAdornmentChar(l:underline)
            let l:adorn = s:MakeAdornment(l:char, l:width)
            return {'output': [l:line, l:adorn], 'consumed': 2}
        endif
    endif

    return {'output': [l:line], 'consumed': 1}
endfunction

" Detect header range around current line
" Returns [first_line, last_line] of the header, or [current, current] for plain text
function! s:DetectHeaderRange(lnum)
    let l:cur = getline(a:lnum)
    let l:above = a:lnum > 1 ? getline(a:lnum - 1) : ''
    let l:below = a:lnum < line('$') ? getline(a:lnum + 1) : ''
    let l:below2 = a:lnum + 1 < line('$') ? getline(a:lnum + 2) : ''

    " Case 1: Current line is title of overlined header (adornment above and below)
    if s:IsAdornment(l:above) && s:IsAdornment(l:below)
        let l:char_above = s:GetAdornmentChar(l:above)
        let l:char_below = s:GetAdornmentChar(l:below)
        if l:char_above ==# l:char_below
            return [a:lnum - 1, a:lnum + 1]
        endif
    endif

    " Case 2: Current line is overline (adornment with text below and matching adornment)
    if s:IsAdornment(l:cur) && !s:IsAdornment(l:below) && s:IsAdornment(l:below2)
        let l:char_cur = s:GetAdornmentChar(l:cur)
        let l:char_below2 = s:GetAdornmentChar(l:below2)
        if l:char_cur ==# l:char_below2
            return [a:lnum, a:lnum + 2]
        endif
    endif

    " Case 3: Current line is underline of overlined header
    if s:IsAdornment(l:cur) && s:IsAdornment(l:above)
        " Check if line above the adornment above is also matching (that would be title between two adornments)
        " Actually, if current is adornment and above is adornment, we need to check 2 lines up
        " No wait - if cur is underline, above should be title, and above-1 should be overline
        " Let me reconsider...
    endif

    " Case 3: Current line is underline (adornment with non-adornment text above)
    if s:IsAdornment(l:cur) && !s:IsAdornment(l:above) && l:above =~# '\S'
        " Check if this is underline of overlined header (2 lines up is matching adornment)
        let l:above2 = a:lnum > 2 ? getline(a:lnum - 2) : ''
        if s:IsAdornment(l:above2) && s:GetAdornmentChar(l:above2) ==# s:GetAdornmentChar(l:cur)
            return [a:lnum - 2, a:lnum]
        endif
        " Simple underline header
        return [a:lnum - 1, a:lnum]
    endif

    " Case 4: Current line is title with underline below
    if !s:IsAdornment(l:cur) && l:cur =~# '\S' && s:IsAdornment(l:below)
        " Check if this is overlined (adornment above matches below)
        if s:IsAdornment(l:above) && s:GetAdornmentChar(l:above) ==# s:GetAdornmentChar(l:below)
            return [a:lnum - 1, a:lnum + 1]
        endif
        " Simple underline header
        return [a:lnum, a:lnum + 1]
    endif

    " Plain text or unrecognized - just current line
    return [a:lnum, a:lnum]
endfunction

" Normal mode wrapper - detects header context and calls RstHeader
" Optional count parameter repeats the operation (for up/down)
function! RstHeaderNormal(arg, ...)
    let l:save_cursor = getcurpos()
    let l:count = a:0 > 0 ? a:1 : 1
    let l:range = s:DetectHeaderRange(line('.'))
    for i in range(l:count)
        " Capture state before operation
        let l:before = getline(l:range[0], l:range[1])
        execute l:range[0] . ',' . l:range[1] . 'call RstHeader("' . a:arg . '")'
        " Re-detect range after operation (line numbers may have changed)
        let l:range = s:DetectHeaderRange(line('.'))
        let l:after = getline(l:range[0], l:range[1])
        " Exit early if nothing changed (hit limit)
        if l:before == l:after
            break
        endif
    endfor
    call setpos('.', l:save_cursor)
endfunction

" Commands
command! -buffer -range -nargs=1 RstHeader <line1>,<line2>call RstHeader(<q-args>)
command! -buffer -nargs=+ RstHeaderN call call('RstHeaderNormal', split(<q-args>))

" Auto-fix on InsertLeave
" Inspired by https://github.com/habamax/vim-rst/wiki/Auto-adjust-section-delimiters
augroup rst_header_buffer
    autocmd! * <buffer>
    autocmd InsertLeave <buffer> call RstHeaderNormal('fix!')
augroup END

" Buffer-local mappings - visual mode
vnoremap <buffer> <leader>ru :RstHeader up<CR>
vnoremap <buffer> <leader>rd :RstHeader down<CR>
vnoremap <buffer> <leader>rf :RstHeader fix<CR>

" Buffer-local mappings - normal mode (with count support)
nnoremap <buffer> <leader>ru :<C-u>call RstHeaderNormal('up', v:count1)<CR>
nnoremap <buffer> <leader>rd :<C-u>call RstHeaderNormal('down', v:count1)<CR>
nnoremap <buffer> <leader>rf :<C-u>call RstHeaderNormal('fix')<CR>

" Generate mappings for each header character
for s:char in g:rst_header_hierarchy
    execute 'vnoremap <buffer> <leader>r' . s:char . ' :RstHeader ' . s:char . '<CR>'
    execute 'nnoremap <buffer> <leader>r' . s:char . ' :RstHeaderN ' . s:char . '<CR>'
endfor

" ============================================================================
" Unit Tests - Run with :call RstHeaderRunTests()
" ============================================================================

function! s:AssertEqual(expected, actual, msg)
    if a:expected != a:actual
        echohl ErrorMsg
        echom 'FAIL: ' . a:msg
        echom '  Expected: ' . string(a:expected)
        echom '  Actual:   ' . string(a:actual)
        echohl None
        return 0
    endif
    echom 'PASS: ' . a:msg
    return 1
endfunction

function! s:TestIsAdornment()
    let l:pass = 1
    let l:pass = s:AssertEqual(1, s:IsAdornment('==='), 'IsAdornment: simple ===') && l:pass
    let l:pass = s:AssertEqual(1, s:IsAdornment('###########'), 'IsAdornment: long ###') && l:pass
    let l:pass = s:AssertEqual(1, s:IsAdornment('---'), 'IsAdornment: ---') && l:pass
    let l:pass = s:AssertEqual(0, s:IsAdornment('=='), 'IsAdornment: too short ==') && l:pass
    let l:pass = s:AssertEqual(0, s:IsAdornment('Hello'), 'IsAdornment: text') && l:pass
    let l:pass = s:AssertEqual(0, s:IsAdornment(''), 'IsAdornment: empty') && l:pass
    let l:pass = s:AssertEqual(0, s:IsAdornment('=-='), 'IsAdornment: mixed chars') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_OverlinedDown()
    " Test: Overlined header (* * *) going down should become underline-only (=)
    let l:lines = ['*****', 'Title', '*****']
    let l:result = s:ProcessHeader(l:lines, 0, 1)

    let l:pass = 1
    let l:pass = s:AssertEqual(3, l:result.consumed, 'OverlinedDown: consumed 3 lines') && l:pass
    let l:pass = s:AssertEqual(2, len(l:result.output), 'OverlinedDown: output has 2 lines') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[0], 'OverlinedDown: first line is title') && l:pass
    let l:pass = s:AssertEqual('=====', l:result.output[1], 'OverlinedDown: second line is underline') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_UnderlineUp()
    " Test: Underline-only header (=) going up should become overlined (* * *)
    let l:lines = ['Title', '=====']
    let l:result = s:ProcessHeader(l:lines, 0, -1)

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'UnderlineUp: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual(3, len(l:result.output), 'UnderlineUp: output has 3 lines') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[0], 'UnderlineUp: first line is overline') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[1], 'UnderlineUp: second line is title') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[2], 'UnderlineUp: third line is underline') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_OverlinedStaysOverlined()
    " Test: # going down to * should keep overline
    let l:lines = ['#####', 'Title', '#####']
    let l:result = s:ProcessHeader(l:lines, 0, 1)

    let l:pass = 1
    let l:pass = s:AssertEqual(3, l:result.consumed, 'OverlinedStays: consumed 3 lines') && l:pass
    let l:pass = s:AssertEqual(3, len(l:result.output), 'OverlinedStays: output has 3 lines') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[0], 'OverlinedStays: overline is *') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[1], 'OverlinedStays: title preserved') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[2], 'OverlinedStays: underline is *') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_UnderlineStaysUnderline()
    " Test: = going down to - should stay underline-only
    let l:lines = ['Title', '=====']
    let l:result = s:ProcessHeader(l:lines, 0, 1)

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'UnderlineStays: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual(2, len(l:result.output), 'UnderlineStays: output has 2 lines') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[0], 'UnderlineStays: title preserved') && l:pass
    let l:pass = s:AssertEqual('-----', l:result.output[1], 'UnderlineStays: underline is -') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_FixesLength()
    " Test: Mismatched length gets fixed
    let l:lines = ['Title', '=======']  " 7 = but title is 5 chars
    let l:result = s:ProcessHeader(l:lines, 0, 1)

    let l:pass = 1
    let l:pass = s:AssertEqual('-----', l:result.output[1], 'FixesLength: underline matches title width') && l:pass
    return l:pass
endfunction

function! s:TestProcessHeader_NonHeader()
    " Test: Non-header line passes through
    let l:lines = ['Just some text', 'More text']
    let l:result = s:ProcessHeader(l:lines, 0, 1)

    let l:pass = 1
    let l:pass = s:AssertEqual(1, l:result.consumed, 'NonHeader: consumed 1 line') && l:pass
    let l:pass = s:AssertEqual(1, len(l:result.output), 'NonHeader: output has 1 line') && l:pass
    let l:pass = s:AssertEqual('Just some text', l:result.output[0], 'NonHeader: line unchanged') && l:pass
    return l:pass
endfunction

function! s:TestMultipleHeaders()
    " Test: Processing multiple headers in sequence
    let l:lines = ['#####', 'First', '#####', '', '*****', 'Second', '*****']

    let l:output = []
    let l:i = 0
    while l:i < len(l:lines)
        let l:result = s:ProcessHeader(l:lines, l:i, 1)
        call extend(l:output, l:result.output)
        let l:i += l:result.consumed
    endwhile

    let l:pass = 1
    " First header: # -> * (stays overlined)
    let l:pass = s:AssertEqual('*****', l:output[0], 'MultiHeaders: first overline') && l:pass
    let l:pass = s:AssertEqual('First', l:output[1], 'MultiHeaders: first title') && l:pass
    let l:pass = s:AssertEqual('*****', l:output[2], 'MultiHeaders: first underline') && l:pass
    " Blank line
    let l:pass = s:AssertEqual('', l:output[3], 'MultiHeaders: blank preserved') && l:pass
    " Second header: * -> = (loses overline)
    let l:pass = s:AssertEqual('Second', l:output[4], 'MultiHeaders: second title (no overline)') && l:pass
    let l:pass = s:AssertEqual('======', l:output[5], 'MultiHeaders: second underline') && l:pass
    let l:pass = s:AssertEqual(6, len(l:output), 'MultiHeaders: total 6 lines (was 7)') && l:pass
    return l:pass
endfunction

function! s:TestBufferNoExtraLines()
    " Integration test: ensure no extra blank lines when processing whole buffer
    " This tests s:ReplaceLines with actual buffer operations
    new
    let l:lines = ['*****', 'Title', '*****', '', 'Text']
    call setline(1, l:lines)

    " Run RstHeader down on entire buffer
    1,$call RstHeader('down')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(4, len(l:result), 'BufferNoExtra: should have 4 lines (was 5)') && l:pass
    let l:pass = s:AssertEqual('Title', l:result[0], 'BufferNoExtra: title') && l:pass
    let l:pass = s:AssertEqual('=====', l:result[1], 'BufferNoExtra: underline') && l:pass
    let l:pass = s:AssertEqual('', l:result[2], 'BufferNoExtra: blank preserved') && l:pass
    let l:pass = s:AssertEqual('Text', l:result[3], 'BufferNoExtra: text preserved') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestBufferAddOverline()
    " Integration test: ensure overline is added correctly when going up
    new
    let l:lines = ['Title', '=====', '', 'Text']
    call setline(1, l:lines)

    " Run RstHeader up on entire buffer
    1,$call RstHeader('up')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(5, len(l:result), 'BufferAddOver: should have 5 lines (was 4)') && l:pass
    let l:pass = s:AssertEqual('*****', l:result[0], 'BufferAddOver: overline added') && l:pass
    let l:pass = s:AssertEqual('Title', l:result[1], 'BufferAddOver: title') && l:pass
    let l:pass = s:AssertEqual('*****', l:result[2], 'BufferAddOver: underline') && l:pass
    let l:pass = s:AssertEqual('', l:result[3], 'BufferAddOver: blank preserved') && l:pass
    let l:pass = s:AssertEqual('Text', l:result[4], 'BufferAddOver: text preserved') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestSetHeaderToChar_PlainText()
    " Test: Plain text becomes header with specified char
    let l:lines = ['My Title']
    let l:result = s:SetHeaderToChar(l:lines, 0, '=')

    let l:pass = 1
    let l:pass = s:AssertEqual(1, l:result.consumed, 'SetChar_Plain: consumed 1 line') && l:pass
    let l:pass = s:AssertEqual(2, len(l:result.output), 'SetChar_Plain: output has 2 lines') && l:pass
    let l:pass = s:AssertEqual('My Title', l:result.output[0], 'SetChar_Plain: title') && l:pass
    let l:pass = s:AssertEqual('========', l:result.output[1], 'SetChar_Plain: underline') && l:pass
    return l:pass
endfunction

function! s:TestSetHeaderToChar_PlainTextOverlined()
    " Test: Plain text becomes overlined header with * char
    let l:lines = ['My Title']
    let l:result = s:SetHeaderToChar(l:lines, 0, '*')

    let l:pass = 1
    let l:pass = s:AssertEqual(1, l:result.consumed, 'SetChar_PlainOver: consumed 1 line') && l:pass
    let l:pass = s:AssertEqual(3, len(l:result.output), 'SetChar_PlainOver: output has 3 lines') && l:pass
    let l:pass = s:AssertEqual('********', l:result.output[0], 'SetChar_PlainOver: overline') && l:pass
    let l:pass = s:AssertEqual('My Title', l:result.output[1], 'SetChar_PlainOver: title') && l:pass
    let l:pass = s:AssertEqual('********', l:result.output[2], 'SetChar_PlainOver: underline') && l:pass
    return l:pass
endfunction

function! s:TestSetHeaderToChar_ExistingHeader()
    " Test: Existing header converted to different char
    let l:lines = ['Title', '=====']
    let l:result = s:SetHeaderToChar(l:lines, 0, '-')

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'SetChar_Existing: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual(2, len(l:result.output), 'SetChar_Existing: output has 2 lines') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[0], 'SetChar_Existing: title') && l:pass
    let l:pass = s:AssertEqual('-----', l:result.output[1], 'SetChar_Existing: underline changed') && l:pass
    return l:pass
endfunction

function! s:TestSetHeaderToChar_AddOverlineToExisting()
    " Test: Existing underline header gets overline when set to *
    let l:lines = ['Title', '=====']
    let l:result = s:SetHeaderToChar(l:lines, 0, '*')

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'SetChar_AddOver: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual(3, len(l:result.output), 'SetChar_AddOver: output has 3 lines') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[0], 'SetChar_AddOver: overline added') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[1], 'SetChar_AddOver: title') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[2], 'SetChar_AddOver: underline') && l:pass
    return l:pass
endfunction

function! s:TestBufferSetChar()
    " Integration test: RstHeader = on plain text
    new
    call setline(1, ['My Section', '', 'Some text'])

    1call RstHeader('=')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(4, len(l:result), 'BufferSetChar: should have 4 lines') && l:pass
    let l:pass = s:AssertEqual('My Section', l:result[0], 'BufferSetChar: title') && l:pass
    let l:pass = s:AssertEqual('==========', l:result[1], 'BufferSetChar: underline added') && l:pass
    let l:pass = s:AssertEqual('', l:result[2], 'BufferSetChar: blank') && l:pass
    let l:pass = s:AssertEqual('Some text', l:result[3], 'BufferSetChar: text') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestFixHeader_TooLong()
    " Test: Fix underline that is too long
    let l:lines = ['Title', '==========']  " 10 = but title is 5 chars
    let l:result = s:FixHeader(l:lines, 0)

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'Fix_TooLong: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[0], 'Fix_TooLong: title unchanged') && l:pass
    let l:pass = s:AssertEqual('=====', l:result.output[1], 'Fix_TooLong: underline shortened') && l:pass
    return l:pass
endfunction

function! s:TestFixHeader_TooShort()
    " Test: Fix underline that is too short
    let l:lines = ['Long Title Here', '=====']  " 5 = but title is 15 chars
    let l:result = s:FixHeader(l:lines, 0)

    let l:pass = 1
    let l:pass = s:AssertEqual(2, l:result.consumed, 'Fix_TooShort: consumed 2 lines') && l:pass
    let l:pass = s:AssertEqual('Long Title Here', l:result.output[0], 'Fix_TooShort: title unchanged') && l:pass
    let l:pass = s:AssertEqual('===============', l:result.output[1], 'Fix_TooShort: underline lengthened') && l:pass
    return l:pass
endfunction

function! s:TestFixHeader_Overlined()
    " Test: Fix overlined header with mismatched lengths
    let l:lines = ['***', 'Title', '*********']
    let l:result = s:FixHeader(l:lines, 0)

    let l:pass = 1
    let l:pass = s:AssertEqual(3, l:result.consumed, 'Fix_Overlined: consumed 3 lines') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[0], 'Fix_Overlined: overline fixed') && l:pass
    let l:pass = s:AssertEqual('Title', l:result.output[1], 'Fix_Overlined: title unchanged') && l:pass
    let l:pass = s:AssertEqual('*****', l:result.output[2], 'Fix_Overlined: underline fixed') && l:pass
    return l:pass
endfunction

function! s:TestBufferFix()
    " Integration test: RstHeader fix on buffer
    new
    call setline(1, ['My Title', '===', '', 'Text'])

    1,$call RstHeader('fix')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(4, len(l:result), 'BufferFix: should have 4 lines') && l:pass
    let l:pass = s:AssertEqual('My Title', l:result[0], 'BufferFix: title') && l:pass
    let l:pass = s:AssertEqual('========', l:result[1], 'BufferFix: underline fixed') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_PlainText()
    " Test: Plain text returns just current line
    new
    call setline(1, ['Some text', 'More text', 'Even more'])

    let l:range = s:DetectHeaderRange(2)
    let l:pass = 1
    let l:pass = s:AssertEqual([2, 2], l:range, 'DetectPlain: returns current line only') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_OnTitle()
    " Test: Cursor on title with underline below
    new
    call setline(1, ['Title', '=====', 'Text'])

    let l:range = s:DetectHeaderRange(1)
    let l:pass = 1
    let l:pass = s:AssertEqual([1, 2], l:range, 'DetectTitle: includes title and underline') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_OnUnderline()
    " Test: Cursor on underline
    new
    call setline(1, ['Title', '=====', 'Text'])

    let l:range = s:DetectHeaderRange(2)
    let l:pass = 1
    let l:pass = s:AssertEqual([1, 2], l:range, 'DetectUnderline: includes title and underline') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_OnOverlinedTitle()
    " Test: Cursor on title of overlined header
    new
    call setline(1, ['*****', 'Title', '*****', 'Text'])

    let l:range = s:DetectHeaderRange(2)
    let l:pass = 1
    let l:pass = s:AssertEqual([1, 3], l:range, 'DetectOverTitle: includes all 3 lines') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_OnOverline()
    " Test: Cursor on overline
    new
    call setline(1, ['*****', 'Title', '*****', 'Text'])

    let l:range = s:DetectHeaderRange(1)
    let l:pass = 1
    let l:pass = s:AssertEqual([1, 3], l:range, 'DetectOverline: includes all 3 lines') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestDetectRange_OnOverlinedUnderline()
    " Test: Cursor on underline of overlined header
    new
    call setline(1, ['*****', 'Title', '*****', 'Text'])

    let l:range = s:DetectHeaderRange(3)
    let l:pass = 1
    let l:pass = s:AssertEqual([1, 3], l:range, 'DetectOverUnder: includes all 3 lines') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestNormalMode_ShiftDown()
    " Integration test: Normal mode shift down from title
    new
    call setline(1, ['*****', 'Title', '*****', '', 'Text'])
    call cursor(2, 1)  " Position on title

    call RstHeaderNormal('down')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(4, len(l:result), 'NormalDown: should have 4 lines') && l:pass
    let l:pass = s:AssertEqual('Title', l:result[0], 'NormalDown: title') && l:pass
    let l:pass = s:AssertEqual('=====', l:result[1], 'NormalDown: underline (no overline)') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestNormalMode_SetChar()
    " Integration test: Normal mode set char on plain text
    new
    call setline(1, ['My Section', '', 'Text'])
    call cursor(1, 1)

    call RstHeaderNormal('=')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual(4, len(l:result), 'NormalSetChar: should have 4 lines') && l:pass
    let l:pass = s:AssertEqual('My Section', l:result[0], 'NormalSetChar: title') && l:pass
    let l:pass = s:AssertEqual('==========', l:result[1], 'NormalSetChar: underline added') && l:pass

    bwipeout!
    return l:pass
endfunction

function! s:TestNormalMode_ChangeExisting()
    " Integration test: Normal mode change existing header from underline position
    new
    call setline(1, ['Title', '=====', '', 'Text'])
    call cursor(2, 1)  " Position on underline

    call RstHeaderNormal('-')

    let l:result = getline(1, '$')
    let l:pass = 1
    let l:pass = s:AssertEqual('Title', l:result[0], 'NormalChange: title') && l:pass
    let l:pass = s:AssertEqual('-----', l:result[1], 'NormalChange: underline changed') && l:pass

    bwipeout!
    return l:pass
endfunction

function! RstHeaderRunTests()
    echom '====== RstHeader Unit Tests ======'
    let l:total = 0
    let l:passed = 0

    let l:total += 1 | if s:TestIsAdornment() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_OverlinedDown() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_UnderlineUp() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_OverlinedStaysOverlined() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_UnderlineStaysUnderline() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_FixesLength() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestProcessHeader_NonHeader() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestMultipleHeaders() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestBufferNoExtraLines() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestBufferAddOverline() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestSetHeaderToChar_PlainText() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestSetHeaderToChar_PlainTextOverlined() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestSetHeaderToChar_ExistingHeader() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestSetHeaderToChar_AddOverlineToExisting() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestBufferSetChar() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestFixHeader_TooLong() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestFixHeader_TooShort() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestFixHeader_Overlined() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestBufferFix() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_PlainText() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_OnTitle() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_OnUnderline() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_OnOverlinedTitle() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_OnOverline() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestDetectRange_OnOverlinedUnderline() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestNormalMode_ShiftDown() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestNormalMode_SetChar() | let l:passed += 1 | endif
    echom ''
    let l:total += 1 | if s:TestNormalMode_ChangeExisting() | let l:passed += 1 | endif
    echom ''

    echom '====== Results: ' . l:passed . '/' . l:total . ' tests passed ======'
endfunction
