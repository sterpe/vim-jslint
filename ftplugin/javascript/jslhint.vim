"Author: FuDesign2008@163.com
" The plugin is only works with node.js and the installed directory should be
" added to $PATH
"
" need support of nodeJS
if !executable('node')
    echoerr 'nodeJS is not found!'
    finish
endif

"-----------------------------------------------------------------------------
"    for buffer
"-----------------------------------------------------------------------------
"
if matchend(expand('%'), '.js') == -1 || exists('b:jslhint_loaded')
    finish
endif
let b:jslhint_loaded = 1
let b:jshintrc = []
let b:jslintrc = []
let b:undo_cur_seq = 0
let b:line_num = 0
" bind events
if (!exists('g:JSLHint_auto_check') || g:JSLHint_auto_check) &&  !exists('b:jslhint_binding')
    let b:jslhint_binding = 1
    "clear buffer's jshintrc when buffer becoming hidden,
    "so when showing the buffer, it can reload jshintrc automatically
    "au BufHidden <buffer> call s:ClearBuffer()
    au BufEnter <buffer> call s:Check()
    "au InsertLeave <buffer> call s:UpdateIfModified()
    au BufWritePost <buffer> call s:UpdateIfModified()
    "au CursorMoved <buffer> call s:UpdateIfModified()
endif
"
"-----------------------------------------------------------------------------
"    for script
"-----------------------------------------------------------------------------

if exists('s:jslhint_loaded')
    finish
endif
let s:jslhint_loaded = 1
" 0 1

let s:loclist = {}
function! s:loclist.GetStackCount ()
    let stack_count = 0
    try
        silent lolder 9
    catch /E380:/
    endtry
    try
        for i in range(9)
            silent lnewer
            let stack_count = stack_count + 1
        endfor
    catch /E381:/
        return stack_count
    endtry
endfunction


function! s:loclist.Activate ()
    try
        silent lolder 9 " go to the bottom of location list stack
    catch /E380:/
    catch /E788:/
    endtry
    if s:check_loclist > 0
        try
            exe 'silent lnewer ' . s:check_loclist
        catch /E381:/
            echoerr 'Could not activate JSLHint location list  Window.'
        endtry
    endif
endfunction

"@param {List} errors
function! s:loclist.SetList(errors)
    if exists('s:check_loclist')
        " if jshint location list window is already created, reuse it
        call s:loclist.Activate()
        call setloclist(0, a:errors, 'r')
    else
        " one jshint location list window for all buffers
        call setloclist(0, a:errors)
        let s:check_loclist = s:loclist.GetStackCount()
    endif
    "call s:loclist.Open()
endfunction

function! s:loclist.Clear()
    call s:loclist.SetList([])
endfunction

function! s:loclist.Open()
    let num = winnr()
    execute "lopen " . g:JSLHint_win_height
    if num != winnr()
        wincmd p
    endif
endfunction

function! s:loclist.Close()
    execute "lclose"
endfunction

let s:js_lint = 0
if exists('g:JSLHint_jshint_default') && g:JSLHint_jshint_default == 0
    let s:js_lint = 1
endif
" 0 1
let s:is_disabled = 0

let s:pluginPath = expand('<sfile>:p:h')

function! s:GetCheckerInfo ()
    if has('win32')
        let s:pluginPath = substitute(s:pluginPath, '/', '\', 'g')
        let prefix= 'cmd.exe /C "cd /d "' . s:pluginPath . '" && node "' . s:pluginPath . '/'
        let suffix = '/run.js""'
    else
        let prefix = 'cd "' . s:pluginPath . '" && node "' . s:pluginPath . '/'
        let suffix = '/run.js"'
    endif
    return {
        \ 'prefix': prefix,
        \ 'suffix': suffix
        \ }
endfun

let s:checkerInfo = s:GetCheckerInfo()

if !exists('g:JSLHint_highlight_error') || g:JSLHint_highlight_error
    let g:JSLHint_highlight_error = 1
    highlight link JSLHintError SpellBad
endif
if !exists('g:JSLHint_win_height')
    let g:JSLHint_win_height = ''
endif

" .jshintrc or .jslintrc
" @param {Boolean} is_jslintrc
"
function! s:SetBuffer ()
    if !exists("b:jslhint_loaded")
        return
    endif
    let jsrc = []
    let jsrc_file = s:js_lint ? '.jslintrc' : '.jshintrc'
    " try to find .jshintrc or .jslintrc in project.
    " try to find the .jshintrc or .jslintrc in ancestor directory in 6 times
    " In most cases, 6 times is enough.
    let up_limit = 6
    let counter = 0
    let temp_dir = expand('%:p:h')
    let project_jsrc = ''
    while (counter < up_limit && strlen(temp_dir) > 1)
        let counter = counter + 1
        if filereadable(temp_dir . '/' . jsrc_file)
            let project_jsrc = temp_dir . '/' .jsrc_file
            " to break the while-loop
            let counter = up_limit
        else
            "up to parent directory
            let temp_dir = fnamemodify(temp_dir, ':h')
        endif
    endwhile
    "try to find user's .jshintrc only when the project has no .jshintrc
    if len(project_jsrc) > 2 && filereadable(project_jsrc)
        let jsrc = readfile(project_jsrc)
    else
        let user_jsrc = expand('~/' . jsrc_file)
        if filereadable(user_jsrc)
            let jsrc =  readfile(user_jsrc)
        endif
    endif
    "set buffer's jsrc
    if s:js_lint
        let b:jslintrc = jsrc
    else
        let b:jshintrc = jsrc
    endif
endfunction
"
" echo checker's configuration
"
function! s:EchoConfig()
    if !exists("b:jslhint_loaded")
        return
    endif
    if s:js_lint
        echo b:jslintrc
    else
        echo b:jshintrc
    endif
endfunction
"
" clear buffer
"
function! s:ClearBuffer()
    if !exists("b:jslhint_loaded")
        return
    endif
    "clear jsrc
    if s:js_lint
        let b:jslintrc = []
    else
        let b:jshintrc = []
    endif
    call s:ClearUI()
endfunction

" update jshint message
"
function! s:UpdateCheck()
    if !exists("b:jslhint_loaded")
        return
    endif
    silent call s:Check()
    silent call s:ShowLineError()
endfunction
"
"
function! s:ToggleChecker()
    if !exists("b:jslhint_loaded")
        return
    endif
    let s:js_lint = s:js_lint ? 0 : 1
    " update ui
    if s:is_disabled
        call s:ClearUI()
    else
        call s:UpdateCheck()
    endif
    echomsg ['JSHint', 'JSLint'][s:js_lint]. ' is ' . ['enabled', 'disabled'][s:is_disabled] . '.'
endfunction
"
"function s:JSLHintToggle, to disabled/enable jshint
"
function! s:ToggleEnable()
    if !exists("b:jslhint_loaded")
        return
    endif
    let s:is_disabled = s:is_disabled ? 0 : 1
    " update ui
    if s:is_disabled
        call s:ClearUI()
    else
        call s:UpdateCheck()
    endif
    echomsg ['JSHint', 'JSLint'][s:js_lint]. ' is ' . ['enabled', 'disabled'][s:is_disabled] . '.'
endfunction
"
" PrintLongMsg() prints [long] message up to (&columns-1) length
" guaranteed without "Press Enter" prompt.
"
" @param {String} msg
"
function s:PrintLongMsg(msg)
    let x=&ruler | let y=&showcmd
    set noruler noshowcmd
    redraw
    echo a:msg
    let &ruler=x | let &showcmd=y
endfun
"
"
"
function! s:ClearUI()
    " Delete previous matches
    let matches = getmatches()
    for matchId in matches
        if matchId['group'] == 'JSLHintError'
            call matchdelete(matchId['id'])
        endif
    endfor
    let b:matchedlines = {}
    call s:loclist.Clear()
endfunction
"
" format the result of jshint checker
" @param {String} result
" @param {Integer} start_line
" @return {List}
function! s:FormatResult (result, start_line)
    if !exists("b:jslhint_loaded")
        return []
    endif
    let output = split(a:result, "\n")
    let loc_list = []
    let buf_num = bufnr('%')
    let b:matchedlines = {}
    for error in output
        " Match {line}:{char}:{error or warn}:{message}
        let parts = matchlist(error, '\v(\d+):(\d+):([A-Z]+):(.*)')
        if empty(parts)
            continue
        endif
        " Get line relative to selection
        if s:js_lint
            let line_num = parts[1] + (a:start_line - 1) - len(b:jslintrc)
        else
            " parst[1] starts at 0
            let line_num = parts[1] + (a:start_line - 1)
        endif
        let error_msg = parts[4]
        if line_num >= 1
            " Store the error for an error under the cursor
            let b:matchedlines[line_num] = error_msg
            if g:JSLHint_highlight_error == 1
                call matchadd('JSLHintError', '\v%' . line_num . 'l\S.*(\S|$)')
            endif
        endif
        " Add line to  list
        call add(loc_list, {
            \ 'bufnr' : buf_num,
            \ 'lnum' : line_num,
            \ 'col' : parts[2],
            \ 'text' : error_msg,
            \ 'type' : parts[3] == 'ERROR' ? 'E' : 'W'
            \ })
    endfor

    return loc_list
endfunction

function! s:Check()
    if !exists("b:jslhint_loaded")
        return
    endif
    call s:ClearUI()
    if s:is_disabled
        return
    endif
    let jsrc = s:js_lint ? b:jslintrc : b:jshintrc
    if len(jsrc) == 0
        call s:SetBuffer()
        let jsrc = s:js_lint ? b:jslintrc : b:jshintrc
    endif
    " Detect range
    if a:firstline == a:lastline
        " Skip a possible shebang line, e.g. for node.js script.
        let start_line = getline(1)[0:1] == '#!' ? 2 : 1
        let end_line = '$'
    else
        let start_line = a:firstline
        let end_line = a:lastline
    endif

    let js_content = join(getline(start_line, end_line), "\n") . "\n"
    if len(js_content) == 0
        return
    endif
    let cmd = s:checkerInfo['prefix'] . (s:js_lint ? 'jslint' : 'jshint'). s:checkerInfo['suffix']
    if s:js_lint
        let output = system(cmd, join(jsrc, "\n") . "\n" . js_content)
    else
        let jsrc_len = len(jsrc) . "\n"
        let output = system(cmd, jsrc_len . join(jsrc, "\n") . "\n" . js_content)
    endif
    if v:shell_error
        echoerr output
        echoerr 'could not invoke JSLHint!'
        let s:is_disabled = 1
        return
    end
    let errorList = s:FormatResult(output, start_line)
    call s:loclist.SetList(errorList)
endfunction

" show jshint message for cursor position if the message is exists
" tracing line number for performance
function s:ShowLineError()
    if !exists("b:jslhint_loaded")
        return
    endif
    let line_num = getpos('.')[1]
    if line_num == b:line_num
        return
    endif
    let b:line_num = line_num
    " Bail if RunJSLHint hasn't been called yet
    if !exists('b:matchedlines')
        return
    endif
    if has_key(b:matchedlines, line_num)
        let  msg = get(b:matchedlines, line_num)
        call s:PrintLongMsg(msg)
    endif
endfunction

" for good performance
" only call UpdateCheck if modified
function! s:UpdateIfModified()
    let undo_seq = undotree()['seq_cur']
    if undo_seq == b:undo_cur_seq
        call s:ShowLineError()
    else
        let b:undo_cur_seq = undo_seq
        call s:UpdateCheck()
    endif
endfunction

" export commands
if exists(':UpdateCheck') != 2
    command! JSToggle :call s:ToggleChecker()
    command! JSToggleEnable :call s:ToggleEnable()
    command! JSUpdate :call s:UpdateCheck()
    command! JSClear :call s:ClearBuffer()
    command! JSrc :call s:EchoConfig()
endif

"

