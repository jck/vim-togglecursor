" ============================================================================
" File:         togglecursor.vim 
" Description:  Toggles cursor shape in the terminal
" Maintainer:   John Szakmeister <john@szakmeister.net>
" License:      Same license as Vim.
" ============================================================================

if exists('g:loaded_togglecursor') || &cp || !has("cursorshape")
  finish
endif
let g:loaded_togglecursor = 1

let s:cursorshape_underline = "\<Esc>]50;CursorShape=2\x7"
let s:cursorshape_line = "\<Esc>]50;CursorShape=1\x7"
let s:cursorshape_block = "\<Esc>]50;CursorShape=0\x7"

let s:xterm_underline = "\<Esc>[4 q"
let s:xterm_line = "\<Esc>[6 q"
let s:xterm_block = "\<Esc>[2 q"

let s:in_tmux = exists("$TMUX")

let s:supported_terminal = ''

" Check for supported terminals.
if !has("gui_running")
    if (has("macunix") && $TERM_PROGRAM == "iTerm.app") || $KONSOLE_DBUS_SESSION != ""
        " Konsole and  iTerm support using CursorShape.
        let s:supported_terminal = 'cursorshape'
    elseif $XTERM_VERSION != ''
        let s:supported_terminal = 'xterm'
    endif
endif

let g:togglecursor_default = 'block'
let g:togglecursor_insert =
            \ (s:supported_terminal == 'xterm') ? 'underline' : 'line'
let g:togglecursor_leave = 'block'


function! s:TmuxEscape(line)
    " Tmux has an escape hatch for talking to the real terminal.  Use it.
    let escaped_line = substitute(a:line, "\<Esc>", "\<Esc>\<Esc>", 'g')
    return "\<Esc>Ptmux;" . escaped_line . "\<Esc>\\"
endfunction

function! s:GetEscapeCode(shape)
    return s:{s:supported_terminal}_{a:shape}
endfunction

function! s:ToggleCursorInit()
    if s:supported_terminal == ''
        return
    endif

    let new_si = s:GetEscapeCode(g:togglecursor_insert)
    let new_ei = s:GetEscapeCode(g:togglecursor_default)

    if s:in_tmux
        let &t_EI = s:TmuxEscape(new_ei)
        let &t_SI = s:TmuxEscape(new_si)
    else
        let &t_EI = new_ei
        let &t_SI = new_si
    endif
endfunction

function! s:ToggleCursorLeave()
    if s:supported_terminal == ''
        return ''
    endif

    " One of the last codes emitted to the terminal before exiting is the "out
    " of termcap" sequence.  Tack our escape sequence to change the cursor type
    " onto the end of the sequence.
    let &t_te .= s:GetEscapeCode(g:togglecursor_leave)
endfunction

augroup ToggleCursorStartup
    autocmd!
    autocmd VimEnter * call <SID>ToggleCursorInit()
    autocmd VimLeave * call <SID>ToggleCursorLeave()
augroup END
