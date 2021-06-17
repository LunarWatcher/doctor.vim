vim9script

# Internal variables {{{
var buffID = -1
# }}}
# Config {{{
g:DoctorPromptCharacter = "❯"
# }}}
# Mode management {{{

def doctor#EnterInsert()
    setlocal nomod
    for [variable, _] in b:variables->items()
        exec 'set no' .. variable
    endfor
enddef

def doctor#LeaveInsert()
    setlocal nomod
    for [variable, enabled] in b:variables->items()
        if enabled
            exec 'set ' .. variable
        endif
    endfor
enddef

# }}}
# "AI" core {{{


# }}}
# Input and buffer management {{{
def doctor#PromptEnter(text: string)
    appendbufline(buffID, line('$') - 1, text)
enddef

def doctor#InitializeResponses()
    if !exists('b:DoctorData') || type(b:DoctorData) != v:t_dict
        b:DoctorData = {}
    endif

    b:DoctorData["doctor-hello"] = [ 
        'Hello.',
        'Hi',
        'Hiya',
    ]

enddef

# TODO: figure out how to better integrate this into i.e. `tab command`
def doctor#GenerateBuffer()
    # New buffer
    vnew

    setlocal noswapfile
    setlocal bufhidden=hide
    setlocal nobuflisted

    # Clean up the buffer a bit
    setlocal buftype=prompt

    b:variables = {
        \ 'number': &number,
        \ 'cul': &cul,
        \ 'cuc': &cuc
    \ }
    
    buffID = bufnr('%')

    # Customize the prompt
    prompt_setprompt(s:buffID, g:DoctorPromptCharacter .. ' ')
    prompt_setcallback(s:buffID, function('doctor#PromptEnter'))


    # AU group for the buffer {{{
    augroup DoctorVimAUGroup
        au!

        autocmd InsertEnter <buffer> doctor#EnterInsert()
        autocmd InsertLeave <buffer> doctor#LeaveInsert()

    augroup END
    # }}}
    
    doctor#InitializeResponses()

    setline(1, "This should be text that shows up prior to the prompt")
    startinsert

enddef
# }}}
