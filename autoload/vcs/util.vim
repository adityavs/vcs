" Author:  Eric Van Dewoestine
" Version: $Revision$
"
" Description: {{{
"   see http://eclim.sourceforge.net/vim/common/vcs.html
"
" License:
"
" Copyright (c) 2005 - 2006
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"      http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.
"
" }}}

" GetRevision() {{{
" Gets the current revision of the current file.
function eclim#vcs#util#GetRevision ()
  let revision = '0'

  let cwd = getcwd()
  let dir = expand('%:p:h')
  exec 'lcd ' . dir
  try
    if isdirectory(dir . '/CVS')
      let status = system('cvs status ' . expand('%:t'))
      let pattern = '.*Working revision:\s*\([0-9.]\+\)\s*.*'
      if status =~ pattern
        let revision = substitute(status, pattern, '\1', '')
      endif
    elseif isdirectory(dir . '/.svn')
      let info = system('svn info ' . expand('%:t'))
      let pattern = '.*Last Changed Rev:\s*\([0-9]\+\)\s*.*'
      if info =~ pattern
        let revision = substitute(info, pattern, '\1', '')
      endif
    endif
  finally
    exec 'lcd ' . cwd
  endtry

  return revision
endfunction " }}}

" GetPreviousRevision() {{{
" Gets the previous revision of the current file.
function eclim#vcs#util#GetPreviousRevision ()
  let revision = '0'

  let cwd = getcwd()
  let dir = expand('%:p:h')
  exec 'lcd ' . dir
  try
    if isdirectory(dir . '/CVS')
      let log = system('cvs log ' . expand('%:t'))
      let lines = split(log, '\n')
      call filter(lines, 'v:val =~ "^revision [0-9.]\\+\\s*$"')
      if len(lines) >= 2
        let revision = substitute(lines[1], '^revision \([0-9.]\+\)\s*.*', '\1', '')
      endif
    elseif isdirectory(dir . '/.svn')
      let log = system('svn log -q --limit 2 ' . expand('%:t'))
      let lines = split(log, '\n')
      if len(lines) == 5 && lines[1] =~ '^r[0-9]\+' && lines[3] =~ '^r[0-9]\+'
        let revision = substitute(lines[3], '^r\([0-9]\+\)\s.*', '\1', '')
      endif
    endif
  finally
    exec 'lcd ' . cwd
  endtry

  return revision
endfunction " }}}

" GetRevisions() {{{
" Gets a list of revision numbers for the current file.
function eclim#vcs#util#GetRevisions ()
  let revisions = []

  let cwd = getcwd()
  let dir = expand('%:p:h')
  exec 'lcd ' . dir
  try
    if isdirectory(dir . '/CVS')
      let log = system('cvs log ' . expand('%:t'))
      let lines = split(log, '\n')
      call filter(lines, 'v:val =~ "^revision [0-9.]\\+\\s*$"')
      call map(lines, 'substitute(v:val, "^revision \\([0-9.]\\+\\)\\s*$", "\\1", "")')
      let revisions = lines
    elseif isdirectory(dir . '/.svn')
      let log = system('svn log -q ' . expand('%:t'))
      let lines = split(log, '\n')
      call filter(lines, 'v:val =~ "^r[0-9]\\+\\s.*"')
      call map(lines, 'substitute(v:val, "^r\\([0-9]\\+\\)\\s.*", "\\1", "")')
      let revisions = lines
    endif
  finally
    exec 'lcd ' . cwd
  endtry

  return revisions
endfunction " }}}

" CommandCompleteRevision(argLead, cmdLine, cursorPos) {{{
" Custom command completion for revision numbers out of viewvc.
function! eclim#vcs#util#CommandCompleteRevision (argLead, cmdLine, cursorPos)
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let args = eclim#util#ParseArgs(cmdLine)
  let argLead = cmdLine =~ '\s$' ? '' : args[len(args) - 1]

  let revisions = eclim#vcs#util#GetRevisions()
  call filter(revisions, 'v:val =~ "^' . argLead . '"')
  return revisions
endfunction " }}}

" vim:ft=vim:fdm=marker
