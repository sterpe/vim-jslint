"Author: srterpe@gmail.com
"

if exists("b:did_jslint_plugin")
  finish
else
  let b:did_lint_plugin = 1
  if (!executable('node'))
    echoerr 'LintStartupError: NodeJS executable `node` not found in path.'
    finish
  endif
  if (!exists("b:lint_disabled"))
    let b:lint_disabled = 0
  endif
endif

let s:plugin_path = expand('<sfile>:p:h') 

function! s:InitLintPlugin()
 
  let b:last_changedtick = b:changedtick
 
  if has("win32")
    let s:plugin_path = substitute(s:plugin_path, '/', '\', 'g')
  endif

  let s:cmd = "node " . s:plugin_path . "/jslint"
  
  highlight link LintError SpellBad
  
  au BufEnter <buffer> call s:Lint()
  au InsertEnter <buffer> call s:RecordCurrentTick()
  au InsertLeave <buffer> call s:MaybeLint()
  au CursorMoved <buffer> call s:MaybeLint()

endfunction

function! s:RunLintCmd(cmd, from, to)

  let l:javascript = join(getline(a:from, a:to),"\n")
  return system(a:cmd, l:javascript)

endfunction

function! s:HighlightLintErrors(lint) 
  for l:element in split(a:lint, '\n')
    let l:data = matchlist(l:element, '\m\(\d\+\):\(\d\+\):\(.*\)')
    if !empty(l:data) 
      let l:line = l:data[1]
      let l:column = l:data[2]
      let l:msg = l:data[3]
      call matchadd('LintError', '\m\%' . l:line . 'l\(\(\S\p*\)\|\(\s\+\)\)$')
      "'l\(\S\p*\|\s*$\)')
    "echoerr l:msg
    endif
  endfor
endfunction
 
function! s:Lint()

  if b:lint_disabled == 1
    return
  endif

  let l:lint = s:RunLintCmd(s:cmd, 1, '$')
  
  if v:shell_error
    echoerr "Could not invoke Linter: " . l:lint
    let b:lint_disabled = 1
    return 1
  end
  
  call s:HighlightLintErrors(l:lint)
  "echom l:lint
  redraw! 

endfunction 

function! s:MaybeLint()

    if b:last_changedtick != b:changedtick
      let b:last_changedtick = b:changedtick
      call clearmatches()
      call s:Lint()
    endif

endfunction

function! s:RecordCurrentTick() 

  let b:last_changedtick = b:changedtick

endfunction

call s:InitLintPlugin()
