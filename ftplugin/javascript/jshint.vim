"Author: FuDesign2008@163.com
" The plugin is only works with node.js and the installed directory should be
" added to $PATH
"
if exists('b:jshint_loaded')
    finish
endif
let b:jshint_loaded = 1
let b:jshintrc = []

" environment
"
" only support nodeJS
if !executable('node')
    echoerr 'Node.js is not found!'
    finish
endif

"let s:install_dir = expand('<sfile>:p:h')
let s:plugin_path = expand('<sfile>:p:h') . '/jshint/'

if has('win32')
    let s:plugin_path = substitute(s:plugin_path, '/', '\', 'g')
    let s:cmd = 'cmd.exe /C "cd /d "' . s:plugin_path . '" && node "' . s:plugin_path . 'runjshint.js""'
else
    let s:cmd = 'cd "' . s:plugin_path . '" && node "' . s:plugin_path . 'runjshint.js"'
endif

highlight link JSHintError SpellBad

if !exists('g:JSHint_highlight_error')
    let g:JSHint_highlight_error = 1
endif

"

" .jshintrc


if !exists('*s:SetBufferJSHintrc')
    function! s:SetBufferJSHintrc ()
        if !exists("b:jshint_loaded")
            return
        endif
        let jshintrc = []
        " try to find .jshintrc in project.
        " try to find the .jshintrc in ancestor directory in 6 times
        " In most cases, 6 times is enough.
        let up_limit = 6
        let counter = 0
        let temp_dir = expand('%:p:h')
        let project_jshint_rc = ''
        while (counter < up_limit && strlen(temp_dir) > 1)
            let counter = counter + 1
            if filereadable(temp_dir . '/.jshintrc')
                let project_jshint_rc = temp_dir . '/.jshintrc'
                " to break the while-loop
                let counter = up_limit
            else
                "up to parent directory
                let temp_dir = fnamemodify(temp_dir, ':h')
            endif
        endwhile

        "try to find user's .jshintrc only when the project has no .jshintrc
        if len(project_jshint_rc) > 2 && filereadable(project_jshint_rc)
            let jshintrc =  jshintrc + readfile(project_jshint_rc)
        else
            let user_jshint_rc = expand('~/.jshintrc')
            if filereadable(user_jshint_rc)
                let jshintrc = jshintrc +  readfile(user_jshint_rc)
            endif
        endif
        "set buffer's jshintrc
        let b:jshintrc = jshintrc
    endfunction
endif

if !exists('*s:EchoJSHintrc')
    function! s:EchoJSHintrc()
        if !exists("b:jshint_loaded")
            return
        endif
        echo b:jshintrc
    endfunction
endif

if !exists('*s:ClearBufferJSHintrc')
    function! s:ClearBufferJSHintrc()
        if !exists("b:jshint_loaded")
            return
        endif
        let b:jshintrc = []
    endfunction
endif


"
" function s:JSHintUpdate
if !exists('*s:JSHintUpdate')
    " update jshint message
    function! s:JSHintUpdate()
        if !exists("b:jshint_loaded")
            return
        endif
        silent call s:JSHint()
        call s:ShowCursorJSHintMsg()
    endfunction
endif
"
"function s:JSHintToggle, to disabled/enable jshint
if !exists('*s:JSHintToggle')
    function! s:JSHintToggle()
        if !exists("b:jshint_loaded")
            return
        endif
        if !exists('s:jshint_disabled') || !s:jshint_disabled
            let s:jshint_disabled = 1
            silent call s:JSHintUpdate()
        else
            let s:jshint_disabled = 0
            silent call s:JSHintClear()
        endif
        echo 'JSHint ' . ['enabled', 'disabled'][s:jshint_disabled] . '.'
    endfunction
endif
"
" function s:PrintLongMsg
if !exists('*s:PrintLongMsg')
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
endif
"
" functiion s:JSHintClear
if !exists('*s:JSHintClear')
    function! s:JSHintClear()
        if !exists("b:jshint_loaded")
            return
        endif
        " Delete previous matches
        let matches = getmatches()
        for matchId in matches
            if matchId['group'] == 'JSHintError'
                call matchdelete(matchId['id'])
            endif
        endfor
        let b:matchedlines = {}
    endfunction
endif
"

"function s:JSHintResultFormat
if !exists('*s:JSHintResultFormat')
    " format the result of jshint checker
    " @param {String} result
    " @param {Integer} start_line
    " @return {List}
    function! s:JSHintResultFormat (result, start_line)
        if !exists("b:jshint_loaded")
            return []
        endif
        let jshint_output = split(a:result, "\n")
        let hint_list = []
        let buf_num = bufnr('%')
        let file_name = expand('%:t')
        for error in jshint_output
            " Match {line}:{char}:{error or warn}:{message}
            let parts = matchlist(error, '\v(\d+):(\d+):([A-Z]+):(.*)')
            if empty(parts)
                continue
            endif
            " Get line relative to selection
            let line_num = parts[1] + (a:start_line - 1)
            let error_msg = parts[4]

            if line_num < 1
                echoerr '[ERROR] .jshintrc is error: ' . error_msg
            else
                " Store the error for an error under the cursor
                let b:matchedlines[line_num] = error_msg
                if g:JSHint_highlight_error == 1
                    call matchadd('JSHintError', '\v%' . line_num . 'l\S.*(\S|$)')
                endif
                " Add line to  list
                call add(hint_list, {
                    \ 'bufnr' : buf_num,
                    \ 'filename' : file_name,
                    \ 'lnum' : line_num,
                    \ 'col' : parts[2],
                    \ 'text' : error_msg,
                    \ 'type' : parts[3] == 'ERROR' ? 'E' : 'W'
                    \ })
            endif
        endfor
        return hint_list
    endfunction
endif
"

"function s:JSHint
if !exists('*s:JSHint')
    "
    function! s:JSHint()
        if !exists("b:jshint_loaded")
            return
        endif
        call s:JSHintClear()
        if exists('s:jshint_disabled') && s:jshint_disabled == 1
            return
        endif

        if len(b:jshintrc) == 0
            call s:SetBufferJSHintrc()
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
        let jshintrc_len = len(b:jshintrc) . "\n"
        let jshint_output = system(s:cmd, jshintrc_len . join(b:jshintrc, "\n") . "\n" . js_content)
        if v:shell_error
            echoerr jshint_output
            echoerr 'could not invoke JSHint!'
            call JSHintToggle()
            return
        end
        let qf_list = s:JSHintResultFormat(jshint_output, start_line)
        if exists('s:jshint_qf')
            " if jshint quickfix window is already created, reuse it
            call s:ActivateJSHintQuickFixWindow()
            call setqflist(qf_list, 'r')
        else
            " one jshint quickfix window for all buffers
            call setqflist(qf_list)
            let s:jshint_qf = s:GetQuickFixStackCount()
        endif
        "noautocmd copen
    endfunction
endif
"

"function s:ShowCursorJSHintMsg
if !exists('*s:ShowCursorJSHintMsg')
    " show jshint message for cursor position if the message is exists
    "
    function s:ShowCursorJSHintMsg()
        if !exists("b:jshint_loaded")
            return
        endif
        " Bail if RunJSHint hasn't been called yet
        if !exists('b:matchedlines')
            return
        endif
        let cursorPos = getpos('.')
        let line_num = cursorPos[1]
        if has_key(b:matchedlines, line_num)
            let  msg = get(b:matchedlines, line_num)
            call s:PrintLongMsg(msg)
            return
        endif
    endfunction
endif
"
"function s:GetQuickFixStackCount
if !exists('*s:GetQuickFixStackCount')
    function s:GetQuickFixStackCount()
        let stack_count = 0
        try
            silent colder 9
        catch /E380:/
        endtry

        try
            for i in range(9)
                silent cnewer
                let stack_count = stack_count + 1
            endfor
        catch /E381:/
            return stack_count
        endtry
    endfunction
endif
"
"function s:ActivateJSHintQuickFixWindow
if !exists('*s:ActivateJSHintQuickFixWindow')
    function s:ActivateJSHintQuickFixWindow()
        try
            silent colder 9 " go to the bottom of quickfix stack
        catch /E380:/
        catch /E788:/
        endtry
        if s:jshint_qf > 0
            try
                exe 'silent cnewer ' . s:jshint_qf
            catch /E381:/
                echoerr 'Could not activate JSHint Quickfix Window.'
            endtry
        endif
    endfunction
endif
"
"
"
" bind events
"

nnoremap <buffer><silent> dd dd:JSHintUpdate<CR>
noremap <buffer><silent> dw dw:JSHintUpdate<CR>
noremap <buffer><silent> u u:JSHintUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:JSHintUpdate<CR>

"au BufLeave <buffer> call s:JSHintClear()
"clear buffer's jshintrc when buffer becoming hidden,
"so when showing the buffer, it can reload jshintrc automatically
au BufHidden <buffer> call s:ClearBufferJSHintrc()
au BufEnter <buffer> call s:JSHint()
au InsertLeave <buffer> call s:JSHint()
"au InsertEnter <buffer> call s:JSHint()
"au BufReadPost <buffer> call s:JSHint()
au BufWritePost <buffer> call s:JSHint()

" due to http://tech.groups.yahoo.com/group/vimdev/message/52115
"if(!has('win32') || v:version>702)
    "au CursorHold <buffer> call s:JSHint()
    "au CursorHoldI <buffer> call s:JSHint()
    "au CursorHold <buffer> call s:ShowCursorJSHintMsg()
"endif
"
au CursorMoved <buffer> call s:ShowCursorJSHintMsg()

"

" export commands
"
if exists(':JSHintUpdate') != 2
    command! JSHintUpdate :call s:JSHintUpdate()
    command! JSHintToggle :call s:JSHintToggle()
    command! JSHintrc :call s:EchoJSHintrc()
endif

"

