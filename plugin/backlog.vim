function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:backlog_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif
  let path = substitute(a:opts.path, '^/', '', '')
  let domain_pattern = '[-0-9a-zA-Z]\+\.\%(git\.\)\=backlog\.\%(jp\|com\)'
  let domains = exists('g:fugitive_backlog_domains') ? g:fugitive_backlog_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let base = matchstr(a:opts.remote, '^\%(https\=://\%([^@/:]*@\)\=\|git://\|[-0-9a-zA-Z]\+@\|ssh://git@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=/\=$')
  if base ==# ''
    return ''
  endif

  let base = substitute(base, '\(' . domain_pattern . '\)\%(/git\|:\)', '\1','')
  let base = substitute(base, domain_pattern, '&/git','')
  let base = substitute(base,'\.git\.','.','')
  let root = 'https://' . substitute(base,':','/','')

  if path =~# '^\.git/refs/heads/'
    return root . '/commit/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/tree/' .path[15:-1]
  elseif path =~# '^\.git/refs/remotes/[^/]\+/.'
    return root . '/tree/' . matchstr(path,'remotes/[^/]\+/\zs.*')
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.commit =~# '^\d\=$'
    let commit = a:opts.repo.rev_parse('HEAD')
  else
    let commit = a:opts.commit
  endif
  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let url = substitute(root . '/tree/' . commit . '/' . path, '/$', '', 'g')
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let escaped_commit = substitute(commit, '#', '%23', 'g')
    let url = root . '/blob/' . escaped_commit . '/' . path
    if get(a:opts, 'line1')
      let url .= '#' . a:opts.line1
      if get(a:opts, 'line2')
        let url .= '-' . a:opts.line2
      endif
    endif
  else
    let url = root . '/commit/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:backlog_url'))
