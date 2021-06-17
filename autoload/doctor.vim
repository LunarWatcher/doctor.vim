vim9script

# Internal variables {{{
var buffID: number = -1
var lastMessage: string = ""
# }}}
# Config {{{
g:DoctorPromptCharacter = "❯"
g:DoctorName = "Mia"
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
# Util functions {{{
def s:upper(text: string): string
    return text[0]->toupper() .. text[1 :]
enddef
# }}}
# "AI" core {{{

def s:random(key: string): string
    var tmp = b:DoctorData[key]
    var result: any = tmp[rand() % tmp->len()]
    if type(result) == v:t_string
        return result
    endif
    var Func = result
    return Func()
enddef

def doctor#ConstructResponse(text: string): list<string>
    # Command processing
    if (text == "/clear")
        :%d
        doctor#ShowGreeting()
        return []
    endif

    # Remove various characters, then split into words.
    # This is largely to simplify parsing when we highroad outside
    # regex.
    # Admittedly, this approach may make re-inserting relevant words
    # harder, but we'll see.
    # On the other hand, using the raw input and parsing out relevant
    # bits from that might be easier.
    var escaped = text->tolower()->substitute('\v[.,\-!?''"]', "", "gi")
    var words = escaped->split(' ')
    if words == ["foo"]
        return ["Bar! " .. s:random("doctor-please") .. ' ' .. s:random("doctor-continue")]
    elseif index(b:DoctorData["doctor-howareyou"], escaped) != -1
        return ["I'm good. " .. s:random("doctor-describe") .. " yourself."]
    else
        return [s:random("doctor-dontunderstand")]
    endif
enddef

# }}}
# Etc. {{{
def doctor#ShowGreeting()
    setline(1, [s:upper(s:random("doctor-hello")) .. '. ' .. s:random('doctor-intro-fragment')])
enddef
# }}}
# Input and buffer management {{{
def doctor#PromptEnter(text: string)
    appendbufline(buffID, line('$') - 1, doctor#ConstructResponse(text))
enddef

def doctor#InitializeResponses()
    if !exists('b:DoctorData') || type(b:DoctorData) != v:t_dict
        b:DoctorData = {}
    endif

    # We need to initialize a bunch of words 

    # And this is where vim9script shines -- no need to escape every single line here
    # Greetings, salutations, and other crap like that {{{
    b:DoctorData["doctor-hello"] = [
        'hello',
        'hi',
        'hiya',
    ]
    b:DoctorData['doctor-intro-fragment'] = [
        () => ( "I'm " .. g:DoctorName ),
        () => ( s:random('doctor-problem') )
    ]
    b:DoctorData['doctor-problem'] = [
        "What may I do for you today?"
    ]
    # }}}
    # Output fragments{{{
    b:DoctorData["doctor-sorry"] = [
        'sorry', "I'm sorry", 'I apologize',
    ]
    b:DoctorData["doctor-please"] = [
        'please'
    ]
    b:DoctorData["doctor-describe"] = [
        'Tell me about', 'Talk about',
        'Discuss', 'Tell me more about',
        'Elaborate on'
    ]
    # }}}
    # Discussion meta {{{
    b:DoctorData["doctor-howareyou"] = [
        'how are you',
        "howre you"
    ]
    # }}}
    # Fallbacks {{{
    b:DoctorData["doctor-dontunderstand"] = [
        "I don't understand"
    ]
    # }}}

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

    # Mappings {{{
    # This terminal mapping is actually kinda useful
    nnoremap <buffer> <C-d> :exit<cr>
    inoremap <buffer> <C-d> <C-o>:exit<cr

    # }}}

    # AU group for the buffer {{{
    augroup DoctorVimAUGroup
        au!

        autocmd InsertEnter <buffer> doctor#EnterInsert()
        autocmd InsertLeave <buffer> doctor#LeaveInsert()

    augroup END
    # }}}

    doctor#InitializeResponses()

    doctor#ShowGreeting()
    startinsert

enddef
# }}}
