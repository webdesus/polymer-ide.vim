if exists('g:loaded_syntastic_html_polylint_checker')
  finish
endif
let g:loaded_syntastic_html_polylint_checker = 1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_html_polylint_IsAvailable() dict
  return exists('g:polymer_ide#use_syntastic') && g:polymer_ide#use_syntastic  
endfunction



function! SyntaxCheckers_html_polylint_GetLocList() dict

	let list = []
	for key in keys(b:polymer_signs)
		call add(list,{ 'valid': 1, 'lnum': key, 'col': b:polymer_signs[key].col, 'bufnr': bufnr(''), 'text': b:polymer_signs[key].message  }) 
	endfor
	return list
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
  \   'filetype': 'html',
  \   'name': 'polylint',
  \ })

let &cpo = s:save_cpo
unlet s:save_cpo
