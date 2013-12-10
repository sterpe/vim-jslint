"Author: FuDesign2008@163.com
" The plugin is only works with node.js and the installed directory should be
" added to $PATH
"
" need support of nodeJS
if !executable('node')
    echoerr 'nodeJS is not found!'
    finish
endif


if exists('s:jslhint_fix_loaded')
    finish
endif
let s:jslhint_fix_loaded = 1

"autocmd BufEnter * call s:OnBufferEnter()
"autocmd BufLeave * call s:OnBufferLeave()

function! s:OnBufferEnter()
    let fileTypes = ["javascript", "qf", "nerdtree", "tagbar"]
    if !exists('s:just_leave') || s:just_leave == -1 || count(fileTypes, &ft)
        return
    endif

    wincmd p
    if bufnr("%") == s:just_leave
        lclose
        wincmd p
    endif
endfun

function! s:OnBufferLeave ()
    let s:just_leave = &ft == "javascript" ? bufnr("%") : -1
endfun



