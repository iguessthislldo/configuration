function! journal#open_today() abort
  " Get documents directory
  let doc_dir = system('xdg-user-dir DOCUMENTS')
  let doc_dir = substitute(doc_dir, '\n$', '', '')

  let journal_dir = doc_dir . '/journal'
  let date = strftime('%Y-%m-%d')
  let journal_file = journal_dir . '/' . date . '.md'

  " Add plugin bin directory to PATH
  let plugin_bin = g:journal_plugin_dir . '/bin'
  let $PATH = plugin_bin . ':' . $PATH

  " Create directory if it doesn't exist
  if !isdirectory(journal_dir)
    call mkdir(journal_dir, 'p')
  endif

  " Check if file exists
  let is_new = !filereadable(journal_file)

  " Open the file
  execute 'edit ' . fnameescape(journal_file)

  " If new, insert template
  if is_new
    let template_file = g:journal_plugin_dir . '/template.md'

    if filereadable(template_file)
      let template_lines = readfile(template_file)

      let processed_lines = []
      " Process template: replace {{command}} with command output
      for tline in template_lines
        let lines = journal#process_template_line(tline)
        call extend(processed_lines, lines)
      endfor

      " Replace the empty buffer with template lines
      if len(processed_lines) > 0
        call setline(1, processed_lines)
      else
        echom 'Journal: No processed lines to insert from ' . template_file
      endif
    else
      echom 'Journal: Template file not readable: ' . template_file
    endif
  endif
endfunction

function! journal#process_template_line(line) abort
  let line = a:line
  let result_lines = []

  while 1
    let start = match(line, '{{')
    if start == -1
      break
    endif
    let end = match(line, '}}', start)
    if end == -1
      break
    endif

    " Extract command between {{ and }}
    let cmd = strpart(line, start + 2, end - start - 2)

    " Execute command and get output, removing trailing newline
    let output = system(cmd)
    let output = substitute(output, '\n$', '', '')

    " Split output by newlines
    let output_lines = split(output, '\n', 1)

    if len(output_lines) == 1
      " Single line output - keep it on the current line
      let line = strpart(line, 0, start) . output_lines[0] . strpart(line, end + 2)
    else
      " Multi-line output - add first line, then middle lines, then continue
      let first_line = strpart(line, 0, start) . output_lines[0]
      call add(result_lines, first_line)

      " Add middle lines
      for i in range(1, len(output_lines) - 2)
        call add(result_lines, output_lines[i])
      endfor

      " Continue with rest of line after }} + last line of output
      let line = output_lines[-1] . strpart(line, end + 2)
    endif
  endwhile

  call add(result_lines, line)
  return result_lines
endfunction
