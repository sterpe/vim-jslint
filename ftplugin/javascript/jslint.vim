"Author: FuDesign2008@163.com
" The plugin is only works with node.js and the installed directory should be
" added to $PATH
"
if exists('b:jslint_loaded')
    finish
endif
let b:jslint_loaded = 1

" environment
"
" only support nodeJS
if !executable('node')
    echoerr 'Node.js is not found!'
    finish
endif

"let s:install_dir = expand('<sfile>:p:h')
let s:plugin_path = expand('<sfile>:p:h') . '/jslint/'

if has('win32')
    let s:plugin_path = substitute(s:plugin_path, '/', '\', 'g')
    let s:cmd = 'cmd.exe /C "cd /d "' . s:plugin_path . '" && node "' . s:plugin_path . 'runjslint.js""'
else
    let s:cmd = 'cd "' . s:plugin_path . '" && node "' . s:plugin_path . 'runjslint.js"'
endif

highlight link JSLintError SpellBad

if !exists('g:JSLint_highlight_error')
    let g:JSLint_highlight_error = 1
endif

"

" .jslintrc


if !exists('*s:SetBufferJSLintrc')
    function! s:SetBufferJSLintrc ()
        let jslintrc = []
        " try to find .jslintrc in project.
        " try to find the .jslintrc in ancestor directory in 6 times
        " In most cases, 6 times is enough.
        let up_limit = 6
        let counter = 0
        let temp_dir = expand('%:p:h')
        let project_jslint_rc = ''
        while (counter < up_limit && strlen(temp_dir) > 1)
            let counter = counter + 1
            if filereadable(temp_dir . '/.jslintrc')
                let project_jslint_rc = temp_dir . '/.jslintrc'
                " to break the while-loop
                let counter = up_limit
            else
                "up to parent directory
                let temp_dir = fnamemodify(temp_dir, ':h')
            endif
        endwhile

        "try to find user's .jslintrc only when the project has no .jslintrc
        if len(project_jslint_rc) > 2 && filereadable(project_jslint_rc)
            let jslintrc = jslintrc + readfile(project_jslint_rc)
        else
            let user_jslint_rc = expand('~/.jslintrc')
            if filereadable(user_jslint_rc)
                let jslintrc = jslintrc + readfile(user_jslint_rc)
            endif
        endif
        "set buffer's jslintrc
        let b:jslintrc = jslintrc
    endfunction
endif

if !exists('*s:EchoJSLintrc')
    function! s:EchoJSLintrc()
        echo b:jslintrc
    endfunction
endif

if !exists('*s:ClearBufferJSLintrc')
    function! s:ClearBufferJSLintrc()
        let b:jslintrc=0
    endfunction
endif


"
" function s:JSLintToggle
if !exists('*s:JSLintUpdate')
    " update jslint message
    function! s:JSLintUpdate()
        silent call s:JSLint()
        call s:ShowCursorJSLintMsg()
    endfunction
endif
"
"function s:JSLintToggle
" disabled/enable jslint
"
function! s:JSLintToggle()

    if !exists('s:jslint_disabled') || !s:jslint_disabled
        let s:jslint_disabled = 1
        silent call s:JSLintUpdate()
    else
        let s:jslint_disabled = 0
        silent call s:JSLintClear()
    endif

    echo 'JSLint ' . ['enabled', 'disabled'][s:jslint_disabled] . '.'

endfunction
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
" functiion s:JSLintClear
if !exists('*s:JSLintClear')
    function! s:JSLintClear()
        " Delete previous matches
        let matches = getmatches()
        for matchId in matches
            if matchId['group'] == 'JSLintError'
                call matchdelete(matchId['id'])
            endif
        endfor
        let b:matchedlines = {}
    endfunction
endif
"

"function s:JSLintResultFormat
if !exists('*s:JSLintResultFormat')
    " format the result of jslint checker
    " @param {String} result
    " @param {Integer} start_line
    " @return {List}
    function! s:JSLintResultFormat (result, start_line)
        let jslint_output = split(a:result, "\n")
        let lint_list = []
        let jslintrc_len = len(b:jslintrc)
        let buf_num = bufnr('%')
        let file_name = expand('%:t')
        if len(jslint_output) == 1
            " Match {line}:{char}:{OK/ERROR/WARN}:{message}
            let parts = matchlist(error, '\v(\d+):(\d+):([A-Z]+):(.*)')
            if empty(parts)
                return []
            endif
            if parts[3] == 'OK'
                echomsg parts[4]
                return []
            endif
        endif
        for error in jslint_output
            " Match {line}:{char}:{OK/ERROR/WARN}:{message}
            let parts = matchlist(error, '\v(\d+):(\d+):([A-Z]+):(.*)')
            if empty(parts)
                continue
            endif
            " Get line relative to selection
            let line_num = parts[1] + (a:start_line - 1 - jslintrc_len)
            let error_msg = parts[4]

            if line_num < 1
                echoerr 'error in jslintrc, line ' . parts[1] . ', character ' . parts[2] . ': ' . error_msg
            else
                " Store the error for an error under the cursor
                let b:matchedlines[line_num] = error_msg
                if g:JSLint_highlight_error == 1
                    call matchadd('JSLintError', '\v%' . line_num . 'l\S.*(\S|$)')
                endif
                " Add line to  list
                call add(lint_list, {
                    \ 'bufnr' : buf_num,
                    \ 'filename' : file_name,
                    \ 'lnum' : line_num,
                    \ 'col' : parts[2],
                    \ 'text' : error_msg,
                    \ 'type' : parts[3] == 'ERROR' ? 'E' : 'W'
                    \ })
            endif
        endfor

        return lint_list
    endfunction
endif
"

"function s:JSLint
if !exists('*s:JSLint')
    "
    function! s:JSLint()
        call s:JSLintClear()
        if exists('s:jslint_disabled') && s:jslint_disabled == 1
            return
        endif

        if !exists('*b:jslintrc') || b:jslintrc == 0
            call s:SetBufferJSLintrc()
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

        let js_content = join(b:jslintrc + getline(start_line, end_line), "\n")
        if len(js_content) == 0
            return
        endif
        let jslint_output = system(s:cmd, js_content . "\n")
        if v:shell_error
            echoerr jslint_output
            echoerr 'could not invoke JSLint!'
            call JSLintToggle()
            return
        end

        let qf_list = s:JSLintResultFormat(jslint_output, start_line)
        "if len(qf_list)  == 0
            "return
        "endif

        if exists('s:jslint_qf')
            " if jslint quickfix window is already created, reuse it
            call s:ActivateJSLintQuickFixWindow()
            call setqflist(qf_list, 'r')
        else
            " one jslint quickfix window for all buffers
            call setqflist(qf_list, '')
            let s:jslint_qf = s:GetQuickFixStackCount()
        endif
        "noautocmd copen
    endfunction
endif
"

"function s:ShowCursorJSLintMsg
if !exists('*s:ShowCursorJSLintMsg')
    " show jslint message for cursor position if the message is exists
    "
    function s:ShowCursorJSLintMsg()
        " Bail if RunJSLint hasn't been called yet
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
"function s:ActivateJSLintQuickFixWindow
if !exists('*s:ActivateJSLintQuickFixWindow')
    function s:ActivateJSLintQuickFixWindow()
        try
            silent colder 9 " go to the bottom of quickfix stack
        catch /E380:/
        catch /E788:/
        endtry
        if s:jslint_qf > 0
            try
                exe 'silent cnewer ' . s:jslint_qf
            catch /E381:/
                echoerr 'Could not activate JSLint Quickfix Window.'
            endtry
        endif
    endfunction
endif
"
"
"
" bind events
"

nnoremap <buffer><silent> dd dd:JSLintUpdate<CR>
noremap <buffer><silent> dw dw:JSLintUpdate<CR>
noremap <buffer><silent> u u:JSLintUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:JSLintUpdate<CR>

"au BufLeave <buffer> call s:JSLintClear()
"clear buffer's jslintrc when buffer becoming hidden,
"so when showing the buffer, it can reload jslintrc automatically
au BufHidden <buffer> call s:ClearBufferJSLintrc()
au BufEnter <buffer> call s:JSLint()
au InsertLeave <buffer> call s:JSLint()
"au InsertEnter <buffer> call s:JSLint()
"au BufReadPost <buffer> call s:JSLint()
au BufWritePost <buffer> call s:JSLint()

" due to http://tech.groups.yahoo.com/group/vimdev/message/52115
"if(!has('win32') || v:version>702)
    "au CursorHold <buffer> call s:JSLint()
    "au CursorHoldI <buffer> call s:JSLint()
    "au CursorHold <buffer> call s:ShowCursorJSLintMsg()
"endif
"
au CursorMoved <buffer> call s:ShowCursorJSLintMsg()

"

" export commands
"
if exists(':JSLintUpdate') != 2
    command! JSLintUpdate :call s:JSLintUpdate()
    command! JSLintToggle :call s:JSLintToggle()
    command! JSLintrc :call s:EchoJSLintrc()
endif

"

