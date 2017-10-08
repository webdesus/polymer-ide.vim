" --------------------------------------------------------------------------------------------
" * Copyright (c) 2016 Denis Kurilenko
" * Licensed under the MIT License. See License.txt in the project root for
" * license information.
" * ------------------------------------------------------------------------------------------

let s:processes = {}
let s:handlers = {}
let b:polymer_signs = {} 
let s:plugin_path = expand('<sfile>:h')  
let s:last_completed_items = [] 
let s:server_path =s:plugin_path .'/../node_modules/polymer-editor-service/lib/polymer-editor-server.js'

function! s:_on_stdout(ch, msg)
	if !empty(a:msg) 
        try
            let msg = json_decode(a:msg)
        catch
            return
        endtry
		if exists('s:handlers['. msg.id .']')
			call s:handlers[msg.id].func(msg.value, s:handlers[msg.id].args)	
			unlet s:handlers[msg.id] 
		endif
	endif
endfunction

function! s:bufferModified()
	call s:send_command({'kind': 'fileChanged', 'localPath': expand('%'), 'contents': join(getline(1,'$'), "\n")},'')
	if exists('g:polymer_ide#use_syntastic') && g:polymer_ide#use_syntastic 
		call s:send_command({'kind': 'getWarningsFor', 'localPath': expand('%') },'s:set_warnings')
	else
		call s:send_command({'kind': 'getWarningsFor', 'localPath': expand('%') },'s:show_warnings')
	endif
endfunction

function! s:get_process(cur_folder)
	if !has_key(s:processes, a:cur_folder) 
		let job  = job_start(['node', s:server_path ], {'callback': function('s:_on_stdout')})	
		let s:processes[a:cur_folder] = { 'job': job, 'cmd_id': 0, 'chanel': job_getchannel(job) }
		call s:make_project_processes(a:cur_folder)
		call ch_readraw(s:processes[a:cur_folder].chanel)
		augroup bufferModified
			autocmd!
			autocmd TextChangedI,BufWritePost <buffer> call s:bufferModified()
			if exists('g:polymer_ide#use_snippets') && g:polymer_ide#use_snippets
				autocmd CompleteDone * call s:CompleteDone() 
			endif
			if exists('g:polymer_ide#on_buffer_text_change') && g:polymer_ide#on_buffer_text_change 
				autocmd TextChanged <buffer> call s:bufferModified()
			endif
		augroup END
		let process = s:processes[a:cur_folder]
		let process.chanel = job_getchannel(process.job)
		return process	 
	else	
		let process = s:processes[a:cur_folder]
		let process.chanel = job_getchannel(process.job)
		return process
	endif
endfunction

function! s:CompleteDone()
	if len(s:last_completed_items) == 0
		return
	endif	
  if !exists('v:completed_item') || empty(v:completed_item)
		if len(s:last_completed_items) == 1
			let completed_item = s:last_completed_items[0]
		else
			return
		endif
	else
		let completed_item = v:completed_item
  endif

	let s:last_completed_items = []
	let complete_str = completed_item.word
  if complete_str == ''
    return
  endif

	call UltiSnips#Anon(complete_str, complete_str)
	return 
endfunction

function! s:send_command(msg, handler, ...)
	let process = s:get_process(getcwd())
	let process.cmd_id += 1
	let msg = {'id': process.cmd_id, 'value': a:msg}
  call ch_sendraw(process.chanel, json_encode(msg) . "\n")
	if !empty(a:handler)
		let s:handlers[process.cmd_id] = {'func': function(a:handler), 'args':a:000}
	endif
endfunction

function! s:make_project_processes(path)
	call s:send_command({'kind': 'init', 'basedir': a:path},'')
endfunction

function! s:set_warnings(data, ...)
	if a:data.kind != 'resolution'
		return
	endif
	for warning in a:data.resolution
		let line = warning.sourceRange.start.line + 1
		let column = warning.sourceRange.end.column - 1
		let b:polymer_signs[line] = {'line': line, 'col':column, 'message': warning.message}
	endfor

endfunction
function! s:show_warnings(data, ...)
	if a:data.kind != 'resolution'
		return
	endif
	let sign_name = 'polymer_analyzer'
	exe ':sign define '. sign_name .' text=>> texthl=Error'
	let old_signs = b:polymer_signs
	let b:polymer_signs = {} 
	for warning in a:data.resolution
		let line = warning.sourceRange.start.line + 1
		let b:polymer_signs[line] = {'line': line, 'message': warning.message}
		exe ':sign place '. line .' line='. line .' name='. sign_name .' file=' . expand('%:p') 
	endfor
	for s in items(old_signs) 
		if !has_key(b:polymer_signs, s[0])
			exe ':sign unplace '. s[0] .' file='. expand('%:p')
		endif
	endfor
endfunction

function! s:go_to_definition(data, args)
	if a:data.kind != 'resolution'
		return
	endif
	if has_key(a:data, 'resolution')
		exe a:args[0] . ' ' . getcwd() . '/' . a:data.resolution.file
		call cursor(a:data.resolution.start.line+1, a:data.resolution.start.column+1)
	endif
endfunction

function! s:go_to_documentation(data, ...)
	if a:data.kind != 'resolution'
		return
	endif
	if has_key(a:data, 'resolution')
		pc!
		ped! documentation
		wincmd P
		setlocal ma
		setlocal buftype=nofile
		for line in split(a:data.resolution, '\n')
			call append(line('$'), line)
		endfor
		setlocal noma
		set syntax=markdown
	endif
endfunction


function! s:get_polymer_signs()
	let result = keys(b:polymer_signs)
	call map(result, 'str2nr(v:val)')
	call sort(result)
	return result
endfunction

"public {{
function! polymer_ide#ShowDocumentation()
	call s:send_command({'kind': 'getDocumentationFor', 'localPath': expand('%'), 'position': {'line': line('.') - 1, 'column': col('.') - 1}}, 's:go_to_documentation')
endfunction

function! polymer_ide#GoToDefinition(cmd)
	call s:send_command({'kind': 'getDefinitionFor', 'localPath': expand('%'), 'position': {'line': line('.') - 1, 'column': col('.') - 1}}, 's:go_to_definition', a:cmd)
endfunction

function! polymer_ide#ShowError(line)
	if has_key(b:polymer_signs, a:line)
		call cursor(a:line, 0)
		silent echohl Error | echo b:polymer_signs[a:line].message | echohl None
	endif
endfunction

function! polymer_ide#NextError()
	let cur_line = line('.')
	let move_line = cur_line
	for key in s:get_polymer_signs() 
		if key > cur_line
			let move_line = key
			break
		endif
	endfor
	call polymer_ide#ShowError(move_line)
endfunction

function! polymer_ide#PreviousError()
	let cur_line = line('.')
	let move_line = cur_line
	for key in s:get_polymer_signs() 
		if key > cur_line
			break
		endif
		if key < cur_line
			let move_line = key
		endif
	endfor
	call polymer_ide#ShowError(move_line)
endfunction

function! polymer_ide#Complete(findstart, complWord)
	if a:findstart
		let line = getline('.') 
		let start = col('.') - 1
		while start > 0 && line[start-1] !~ ' '
			let start -= 1
		endwhile
		return start 
	else
		call s:send_command({'kind': 'getTypeaheadCompletionsFor', 'localPath': expand('%'), 'position': {'line': line('.') - 1, 'column': col('.') - 1}},'')
		let definition = json_decode(ch_readraw(s:processes[getcwd()].chanel)).value
		let result = []
		if definition.kind == 'resolution'
			if definition.resolution.kind == 'element-tags'
				for el in definition.resolution.elements
					if match(el.tagname, a:complWord) == 0 || match(el.expandTo, a:complWord) == 0 
						let description = el.description
						if description != '' && len(description) > 62 
							let description = strpart(el.description, 0, 59) . '...'
						endif
						if exists('g:polymer_ide#use_snippets') && g:polymer_ide#use_snippets
							let word = el.expandToSnippet
						else
							let word = el.expandTo
						endif
						call add(result, {'abbr': '<' . el.tagname . '>', 'word': word, 'menu': description})
					endif
				endfor
			elseif definition.resolution.kind == 'attributes'
				for  attr in definition.resolution.attributes
					if match(attr.name, a:complWord) == 0
						let description = attr.description
						if description != '' && len(description) > 62 
							let description = strpart(attr.description, 0, 59) . '...'
						endif
						let word = attr.name
						if attr.type != '' && attr.type != 'boolean' 
							let word = word . '=""' 
						endif
						call add(result, {'abbr': attr.name, 'word': word, 'menu': description, 'kind': '{' . attr.type . '}'})
					endif
				endfor
			endif
		endif
		let s:last_completed_items = result
		return result 
	endif
endfunction

function! polymer_ide#Enable()
		if !filereadable(s:server_path)
			echoerr 'You forgot execute "npm install" command!'
			return 0
		else
			let b:polymer_signs = {} 
			setlocal omnifunc=polymer_ide#Complete
			exe ':cd ' . getcwd()
			call s:bufferModified()
		endif
endfunction
"public }}


