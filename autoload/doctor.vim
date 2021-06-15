let s:buffID = -1

let g:DoctorPromptCharacter = "❯"

" Mode management {{{

fun! doctor#EnterInsert()
    for [variable, _] in b:variables->items()
        exec 'set no' . variable
    endfor
endfun

fun! doctor#LeaveInsert()
    for [variable, enabled] in b:variables->items()
        if enabled
            exec 'set ' . variable
        endif
    endfor
endfun

" }}}

" TODO: figure out how to better integrate this into i.e. `tab command`
fun! doctor#GenerateBuffer()
    " New buffer
    vnew

    " Clean up the buffer a bit
    setlocal buftype=prompt

    let b:variables = {
        \ 'number': &number,
        \ 'cul': &cul,
        \ 'cuc': &cuc
    \ }
    
    let s:buffID = bufnr('%')

    " Customize the prompt
    call prompt_setprompt(s:buffID, g:DoctorPromptCharacter . ' ')


    " AU group for the buffer {{{
    augroup DoctorVimAUGroup
        au!

        autocmd InsertEnter <buffer> call doctor#EnterInsert()
        autocmd InsertLeave <buffer> call doctor#LeaveInsert()
    augroup END
    " }}}

    call setline(1, "This should be text that shows up prior to the prompt")
    startinsert

endfun 
