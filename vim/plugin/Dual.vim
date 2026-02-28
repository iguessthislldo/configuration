" -------------------- Dual --------------------
function DualEdit( ... )
    if genutils#NumberOfWindows() == 1
        execute "80vnew " . join(a:000, " ")
    else
        echo "More than one window is open"
    endif
endfunction

command -nargs=* -complete=file De call DualEdit( '<args>' )

function DualSwap()
    if genutils#NumberOfWindows() == 2
        wincmd r
        wincmd h
        vertical resize 80
    else
        echo "There must be two windows open to swap"
    endif
endfunction

command Ds call DualSwap()
