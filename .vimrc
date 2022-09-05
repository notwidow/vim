" Vim configuration "

syntax on
filetype plugin indent on

set nocompatible

set relativenumber

set termguicolors
set t_Co=256
set cursorline

set smarttab
set tabstop=3
set expandtab
set shiftwidth=3
set softtabstop=3

set autoindent
set smartindent

set incsearch
set ignorecase
set smartcase

set magic

set nomodeline

set ttyfast

set lazyredraw

set clipboard=unnamedplus

set mouse=

set history=50

set timeout
set updatetime=150
set timeoutlen=300

set nobackup
set nowritebackup
set noswapfile
set nowrap

set noshowmatch

set conceallevel=0
set cmdheight=2

set laststatus=2

set wildmenu
set wildignore=.png,.jpg,.jpeg,.pyc

set encoding=utf-8
set fileencoding=utf-8

set scrolloff=8
set sidescrolloff=8

set foldenable

set hidden

set splitright
set splitbelow

set path=**

set background=dark

autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview

" Autopairs "

if exists('g:AutoPairsLoaded') || &cp
  finish
end
let g:AutoPairsLoaded = 1

if !exists('g:AutoPairs')
  let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '`':'`'}
end

if !exists('g:AutoPairsParens')
  let g:AutoPairsParens = {'(':')', '[':']', '{':'}'}
end

if !exists('g:AutoPairsMapBS')
  let g:AutoPairsMapBS = 1
end

if !exists('g:AutoPairsMapCR')
  let g:AutoPairsMapCR = 1
end

if !exists('g:AutoPairsMapSpace')
  let g:AutoPairsMapSpace = 1
end

if !exists('g:AutoPairsCenterLine')
  let g:AutoPairsCenterLine = 1
end

if !exists('g:AutoPairsShortcutToggle')
  let g:AutoPairsShortcutToggle = '<M-p>'
end

if !exists('g:AutoPairsShortcutFastWrap')
  let g:AutoPairsShortcutFastWrap = '<M-e>'
end

if !exists('g:AutoPairsShortcutJump')
  let g:AutoPairsShortcutJump = '<M-n>'
endif

" Fly mode will for closed pair to jump to closed pair instead of insert.
" also support AutoPairsBackInsert to insert pairs where jumped.
if !exists('g:AutoPairsFlyMode')
  let g:AutoPairsFlyMode = 0
endif

" Work with Fly Mode, insert pair where jumped
if !exists('g:AutoPairsShortcutBackInsert')
  let g:AutoPairsShortcutBackInsert = '<M-b>'
endif

if !exists('g:AutoPairsSmartQuotes')
  let g:AutoPairsSmartQuotes = 1
endif


" Will auto generated {']' => '[', ..., '}' => '{'}in initialize.
let g:AutoPairsClosedPairs = {}


function! AutoPairsInsert(key)
  if !b:autopairs_enabled
    return a:key
  end

  let line = getline('.')
  let pos = col('.') - 1
  let before = strpart(line, 0, pos)
  let after = strpart(line, pos)
  let next_chars = split(after, '\zs')
  let current_char = get(next_chars, 0, '')
  let next_char = get(next_chars, 1, '')
  let prev_chars = split(before, '\zs')
  let prev_char = get(prev_chars, -1, '')

  let eol = 0
  if col('$') -  col('.') <= 1
    let eol = 1
  end

  " Ignore auto close if prev character is \
  if prev_char == '\'
    return a:key
  end

  " The key is difference open-pair, then it means only for ) ] } by default
  if !has_key(b:AutoPairs, a:key)
    let b:autopairs_saved_pair = [a:key, getpos('.')]

    " Skip the character if current character is the same as input
    if current_char == a:key
      return "\<Right>"
    end

    if !g:AutoPairsFlyMode
      " Skip the character if next character is space
      if current_char == ' ' && next_char == a:key
        return "\<Right>\<Right>"
      end

      " Skip the character if closed pair is next character
      if current_char == ''
        let next_lineno = line('.')+1
        let next_line = getline(nextnonblank(next_lineno))
        let next_char = matchstr(next_line, '\s*\zs.')
        if next_char == a:key
          return "\<ESC>e^a"
        endif
      endif
    endif

    " Fly Mode, and the key is closed-pairs, search closed-pair and jump
    if g:AutoPairsFlyMode && has_key(b:AutoPairsClosedPairs, a:key)
      if search(a:key, 'W')
        return "\<Right>"
      endif
    endif

    " Insert directly if the key is not an open key
    return a:key
  end

  let open = a:key
  let close = b:AutoPairs[open]

  if current_char == close && open == close
    return "\<Right>"
  end

  " Ignore auto close ' if follows a word
  " MUST after closed check. 'hello|'
  if a:key == "'" && prev_char =~ '\v\w'
    return a:key
  end

  " support for ''' ``` and """
  if open == close
    " The key must be ' " `
    let pprev_char = line[col('.')-3]
    if pprev_char == open && prev_char == open
      " Double pair found
      return repeat(a:key, 4) . repeat("\<LEFT>", 3)
    end
  end

  let quotes_num = 0
  " Ignore comment line for vim file
  if &filetype == 'vim' && a:key == '"'
    if before =~ '^\s*$'
      return a:key
    end
    if before =~ '^\s*"'
      let quotes_num = -1
    end
  end

  " Keep quote number is odd.
  " Because quotes should be matched in the same line in most of situation
  if g:AutoPairsSmartQuotes && open == close
    " Remove \\ \" \'
    let cleaned_line = substitute(line, '\v(\\.)', '', 'g')
    let n = quotes_num
    let pos = 0
    while 1
      let pos = stridx(cleaned_line, open, pos)
      if pos == -1
        break
      end
      let n = n + 1
      let pos = pos + 1
    endwhile
    if n % 2 == 1
      return a:key
    endif
  endif

  return open.close."\<Left>"
endfunction

function! AutoPairsDelete()
  if !b:autopairs_enabled
    return "\<BS>"
  end

  let line = getline('.')
  let pos = col('.') - 1
  let current_char = get(split(strpart(line, pos), '\zs'), 0, '')
  let prev_chars = split(strpart(line, 0, pos), '\zs')
  let prev_char = get(prev_chars, -1, '')
  let pprev_char = get(prev_chars, -2, '')

  if pprev_char == '\'
    return "\<BS>"
  end

  " Delete last two spaces in parens, work with MapSpace
  if has_key(b:AutoPairs, pprev_char) && prev_char == ' ' && current_char == ' '
    return "\<BS>\<DEL>"
  endif

  " Delete Repeated Pair eg: '''|''' [[|]] {{|}}
  if has_key(b:AutoPairs, prev_char)
    let times = 0
    let p = -1
    while get(prev_chars, p, '') == prev_char
      let p = p - 1
      let times = times + 1
    endwhile

    let close = b:AutoPairs[prev_char]
    let left = repeat(prev_char, times)
    let right = repeat(close, times)

    let before = strpart(line, pos-times, times)
    let after  = strpart(line, pos, times)
    if left == before && right == after
      return repeat("\<BS>\<DEL>", times)
    end
  end


  if has_key(b:AutoPairs, prev_char)
    let close = b:AutoPairs[prev_char]
    if match(line,'^\s*'.close, col('.')-1) != -1
      " Delete (|___)
      let space = matchstr(line, '^\s*', col('.')-1)
      return "\<BS>". repeat("\<DEL>", len(space)+1)
    elseif match(line, '^\s*$', col('.')-1) != -1
      " Delete (|__\n___)
      let nline = getline(line('.')+1)
      if nline =~ '^\s*'.close
        if &filetype == 'vim' && prev_char == '"'
          " Keep next line's comment
          return "\<BS>"
        end

        let space = matchstr(nline, '^\s*')
        return "\<BS>\<DEL>". repeat("\<DEL>", len(space)+1)
      end
    end
  end

  return "\<BS>"
endfunction

function! AutoPairsJump()
  call search('["\]'')}]','W')
endfunction
" string_chunk cannot use standalone
let s:string_chunk = '\v%(\\\_.|[^\1]|[\r\n]){-}'
let s:ss_pattern = '\v''' . s:string_chunk . ''''
let s:ds_pattern = '\v"'  . s:string_chunk . '"'

func! s:RegexpQuote(str)
  return substitute(a:str, '\v[\[\{\(\<\>\)\}\]]', '\\&', 'g')
endf

func! s:RegexpQuoteInSquare(str)
  return substitute(a:str, '\v[\[\]]', '\\&', 'g')
endf

" Search next open or close pair
func! s:FormatChunk(open, close)
  let open = s:RegexpQuote(a:open)
  let close = s:RegexpQuote(a:close)
  let open2 = s:RegexpQuoteInSquare(a:open)
  let close2 = s:RegexpQuoteInSquare(a:close)
  if open == close
    return '\v'.open.s:string_chunk.close
  else
    return '\v%(' . s:ss_pattern . '|' . s:ds_pattern . '|' . '[^'.open2.close2.']|[\r\n]' . '){-}(['.open2.close2.'])'
  end
endf

" Fast wrap the word in brackets
function! AutoPairsFastWrap()
  let line = getline('.')
  let current_char = line[col('.')-1]
  let next_char = line[col('.')]
  let open_pair_pattern = '\v[({\[''"]'
  let at_end = col('.') >= col('$') - 1
  normal x
  " Skip blank
  if next_char =~ '\v\s' || at_end
    call search('\v\S', 'W')
    let line = getline('.')
    let next_char = line[col('.')-1]
  end

  if has_key(b:AutoPairs, next_char)
    let followed_open_pair = next_char
    let inputed_close_pair = current_char
    let followed_close_pair = b:AutoPairs[next_char]
    if followed_close_pair != followed_open_pair
      " TODO replace system searchpair to skip string and nested pair.
      " eg: (|){"hello}world"} will transform to ({"hello})world"}
      call searchpair('\V'.followed_open_pair, '', '\V'.followed_close_pair, 'W')
    else
      call search(s:FormatChunk(followed_open_pair, followed_close_pair), 'We')
    end
    return "\<RIGHT>".inputed_close_pair."\<LEFT>"
  else
    normal he
    return "\<RIGHT>".current_char."\<LEFT>"
  end
endfunction

function! AutoPairsMap(key)
  " | is special key which separate map command from text
  let key = a:key
  if key == '|'
    let key = '<BAR>'
  end
  let escaped_key = substitute(key, "'", "''", 'g')
  " use expr will cause search() doesn't work
  execute 'inoremap <buffer> <silent> '.key." <C-R>=AutoPairsInsert('".escaped_key."')<CR>"
endfunction

function! AutoPairsToggle()
  if b:autopairs_enabled
    let b:autopairs_enabled = 0
    echo 'AutoPairs Disabled.'
  else
    let b:autopairs_enabled = 1
    echo 'AutoPairs Enabled.'
  end
  return ''
endfunction

function! AutoPairsReturn()
  if b:autopairs_enabled == 0
    return ''
  end
  let line = getline('.')
  let pline = getline(line('.')-1)
  let prev_char = pline[strlen(pline)-1]
  let cmd = ''
  let cur_char = line[col('.')-1]
  if has_key(b:AutoPairs, prev_char) && b:AutoPairs[prev_char] == cur_char
    if g:AutoPairsCenterLine && winline() * 3 >= winheight(0) * 2
      " Use \<BS> instead of \<ESC>cl will cause the placeholder deleted
      " incorrect. because <C-O>zz won't leave Normal mode.
      " Use \<DEL> is a bit wierd. the character before cursor need to be deleted.
      let cmd = " \<C-O>zz\<ESC>cl"
    end

    " If equalprg has been set, then avoid call =
    " https://github.com/jiangmiao/auto-pairs/issues/24
    if &equalprg != ''
      return "\<ESC>O".cmd
    endif

    " conflict with javascript and coffee
    " javascript   need   indent new line
    " coffeescript forbid indent new line
    if &filetype == 'coffeescript' || &filetype == 'coffee'
      return "\<ESC>k==o".cmd
    else
      return "\<ESC>=ko".cmd
    endif
  end
  return ''
endfunction

function! AutoPairsSpace()
  let line = getline('.')
  let prev_char = line[col('.')-2]
  let cmd = ''
  let cur_char =line[col('.')-1]
  if has_key(g:AutoPairsParens, prev_char) && g:AutoPairsParens[prev_char] == cur_char
    let cmd = "\<SPACE>\<LEFT>"
  endif
  return "\<SPACE>".cmd
endfunction

function! AutoPairsBackInsert()
  if exists('b:autopairs_saved_pair')
    let pair = b:autopairs_saved_pair[0]
    let pos  = b:autopairs_saved_pair[1]
    call setpos('.', pos)
    return pair
  endif
  return ''
endfunction

function! AutoPairsInit()
  let b:autopairs_loaded  = 1
  let b:autopairs_enabled = 1
  let b:AutoPairsClosedPairs = {}

  if !exists('b:AutoPairs')
    let b:AutoPairs = g:AutoPairs
  end

  " buffer level map pairs keys
  for [open, close] in items(b:AutoPairs)
    call AutoPairsMap(open)
    if open != close
      call AutoPairsMap(close)
    end
    let b:AutoPairsClosedPairs[close] = open
  endfor

  " Still use <buffer> level mapping for <BS> <SPACE>
  if g:AutoPairsMapBS
    " Use <C-R> instead of <expr> for issue #14 sometimes press BS output strange words
    execute 'inoremap <buffer> <silent> <BS> <C-R>=AutoPairsDelete()<CR>'
    execute 'inoremap <buffer> <silent> <C-H> <C-R>=AutoPairsDelete()<CR>'
  end

  if g:AutoPairsMapSpace
    " Try to respect abbreviations on a <SPACE>
    let do_abbrev = ""
    if v:version >= 703 && has("patch489")
      let do_abbrev = "<C-]>"
    endif
    execute 'inoremap <buffer> <silent> <SPACE> '.do_abbrev.'<C-R>=AutoPairsSpace()<CR>'
  end

  if g:AutoPairsShortcutFastWrap != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutFastWrap.' <C-R>=AutoPairsFastWrap()<CR>'
  end

  if g:AutoPairsShortcutBackInsert != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutBackInsert.' <C-R>=AutoPairsBackInsert()<CR>'
  end

  if g:AutoPairsShortcutToggle != ''
    " use <expr> to ensure showing the status when toggle
    execute 'inoremap <buffer> <silent> <expr> '.g:AutoPairsShortcutToggle.' AutoPairsToggle()'
    execute 'noremap <buffer> <silent> '.g:AutoPairsShortcutToggle.' :call AutoPairsToggle()<CR>'
  end

  if g:AutoPairsShortcutJump != ''
    execute 'inoremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' <ESC>:call AutoPairsJump()<CR>a'
    execute 'noremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' :call AutoPairsJump()<CR>'
  end

endfunction

function! s:ExpandMap(map)
  let map = a:map
  let map = substitute(map, '\(<Plug>\w\+\)', '\=maparg(submatch(1), "i")', 'g')
  return map
endfunction

function! AutoPairsTryInit()
  if exists('b:autopairs_loaded')
    return
  end

  " for auto-pairs starts with 'a', so the priority is higher than supertab and vim-endwise
  "
  " vim-endwise doesn't support <Plug>AutoPairsReturn
  " when use <Plug>AutoPairsReturn will cause <Plug> isn't expanded
  "
  " supertab doesn't support <SID>AutoPairsReturn
  " when use <SID>AutoPairsReturn  will cause Duplicated <CR>
  "
  " and when load after vim-endwise will cause unexpected endwise inserted.
  " so always load AutoPairs at last

  " Buffer level keys mapping
  " comptible with other plugin
  if g:AutoPairsMapCR
    if v:version >= 703 && has('patch32')
      " VIM 7.3 supports advancer maparg which could get <expr> info
      " then auto-pairs could remap <CR> in any case.
      let info = maparg('<CR>', 'i', 0, 1)
      if empty(info)
        let old_cr = '<CR>'
        let is_expr = 0
      else
        let old_cr = info['rhs']
        let old_cr = s:ExpandMap(old_cr)
        let old_cr = substitute(old_cr, '<SID>', '<SNR>' . info['sid'] . '_', 'g')
        let is_expr = info['expr']
        let wrapper_name = '<SID>AutoPairsOldCRWrapper73'
      endif
    else
      " VIM version less than 7.3
      " the mapping's <expr> info is lost, so guess it is expr or not, it's
      " not accurate.
      let old_cr = maparg('<CR>', 'i')
      if old_cr == ''
        let old_cr = '<CR>'
        let is_expr = 0
      else
        let old_cr = s:ExpandMap(old_cr)
        " old_cr contain (, I guess the old cr is in expr mode
        let is_expr = old_cr  =~ '\V(' && toupper(old_cr) !~ '\V<C-R>'
        let wrapper_name = '<SID>AutoPairsOldCRWrapper'
      end
    end

    if old_cr !~ 'AutoPairsReturn'
      if is_expr
        " remap <expr> to `name` to avoid mix expr and non-expr mode
        execute 'inoremap <buffer> <expr> <script> '. wrapper_name . ' ' . old_cr
        let old_cr = wrapper_name
      end
      " Always silent mapping
      execute 'inoremap <script> <buffer> <silent> <CR> '.old_cr.'<SID>AutoPairsReturn'
    end
  endif
  call AutoPairsInit()
endfunction

" Always silent the command
inoremap <silent> <SID>AutoPairsReturn <C-R>=AutoPairsReturn()<CR>
imap <script> <Plug>AutoPairsReturn <SID>AutoPairsReturn


au BufEnter * :call AutoPairsTryInit()

" Statusline "

set statusline=
set statusline+=%7*\[%n]                                  "buffernr
set statusline+=%1*\ %<%f\                                "File
set statusline+=%2*\ %y\                                  "FileType
set statusline+=%3*\ %{''.(&fenc!=''?&fenc:&enc).''}      "Encoding
set statusline+=%3*\ %{(&bomb?\",BOM\":\"\")}\            "Encoding2
set statusline+=%4*\ %{&ff}\                              "FileFormat (dos/unix..)
set statusline+=%5*\ %{&spelllang}\%{HighlightSearch()}\  "Spellanguage & Highlight on?
set statusline+=%8*\ %=\ row:%l/%L\ (%03p%%)\             "Rownumber/total (%)
set statusline+=%9*\ col:%03c\                            "Colnr
set statusline+=%0*\ \ %m%r%w\ %P\ \

function! HighlightSearch()
  if &hls
    return 'H'
  else
    return ''
  endif
endfunction

hi User1 guifg=#ffdad8  guibg=#880c0e
hi User2 guifg=#000000  guibg=#F4905C
hi User3 guifg=#292b00  guibg=#f4f597
hi User4 guifg=#112605  guibg=#aefe7B
hi User5 guifg=#051d00  guibg=#7dcc7d
hi User7 guifg=#ffffff  guibg=#880c0e gui=bold
hi User8 guifg=#ffffff  guibg=#5b7fbb
hi User9 guifg=#ffffff  guibg=#810085
hi User0 guifg=#ffffff  guibg=#094afe

" Keymaps "

let mapleader=' '

nmap <silent> <leader>x :wq<CR>

" Colorscheme "

if exists('g:colors_name')
    highlight clear
    if exists('syntax_on')
        syntax reset
    endif
endif
let g:colors_name='nightfly'

" Please check that Vim/Neovim is able to run this true-color only theme.
"
" If running in a terminal make sure termguicolors exists and is set.
if has('nvim')
    if has('nvim-0.4') && len(nvim_list_uis()) > 0 && nvim_list_uis()[0]['ext_termcolors'] && !&termguicolors
        " The nvim_list_uis test indicates terminal Neovim vs GUI Neovim.
        " Note, versions prior to Neovim 0.4 did not set 'ext_termcolors'.
        echomsg 'The termguicolors option must be set'
        finish
    endif
else " Vim
    if !has('gui_running') && !exists('&termguicolors')
        echomsg 'A modern version of Vim with termguicolors is required'
        finish
    elseif !has('gui_running') && !&termguicolors
        echomsg 'The termguicolors option must be set'
        echomsg 'Be aware macOS default Vim is broken, use Homebrew Vim instead'
        finish
    endif
endif

" By default do not color the cursor.
let g:nightflyCursorColor = get(g:, 'nightflyCursorColor', v:false)

" By default do use italics in GUI versions of Vim.
let g:nightflyItalics = get(g:, 'nightflyItalics', v:true)

" By default do not use a customized 'NormalFloat' highlight group (for Neovim
" floating windows).
let g:nightflyNormalFloat = get(g:, 'nightflyNormalFloat', v:false)

" By default use the nightly color palette in the `:terminal`
let g:nightflyTerminalColors = get(g:, 'nightflyTerminalColors', v:true)

" By default do not use a transparent background in GUI versions of Vim.
let g:nightflyTransparent = get(g:, 'nightflyTransparent', v:false)

" By default do use undercurls in GUI versions of Vim, including terminal Vim
" with termguicolors set.
let g:nightflyUndercurls = get(g:, 'nightflyUndercurls', v:true)

" By default do not underline matching parentheses.
let g:nightflyUnderlineMatchParen = get(g:, 'nightflyUnderlineMatchParen', v:false)

" By default do display vertical split columns.
let g:nightflyWinSeparator = get(g:, 'nightflyWinSeparator', 1)

" Background and foreground
let s:black      = '#011627'
let s:white      = '#c3ccdc'
" Variations of blue-grey
let s:black_blue = '#081e2f'
let s:dark_blue  = '#092236'
let s:deep_blue  = '#0e293f'
let s:slate_blue = '#2c3043'
let s:regal_blue = '#1d3b53'
let s:steel_blue = '#4b6479'
let s:grey_blue  = '#7c8f8f'
let s:cadet_blue = '#a1aab8'
let s:ash_blue   = '#acb4c2'
let s:white_blue = '#d6deeb'
" Core theme colors
let s:yellow     = '#e3d18a'
let s:peach      = '#ffcb8b'
let s:tan        = '#ecc48d'
let s:orange     = '#f78c6c'
let s:red        = '#fc514e'
let s:watermelon = '#ff5874'
let s:violet     = '#c792ea'
let s:purple     = '#ae81ff'
let s:indigo     = '#5e97ec'
let s:blue       = '#82aaff'
let s:turquoise  = '#7fdbca'
let s:emerald    = '#21c7a8'
let s:green      = '#a1cd5e'
" Extra colors
let s:cyan_blue  = '#296596'

" Specify the colors used by the inbuilt terminal of Neovim and Vim
if g:nightflyTerminalColors
    if has('nvim')
        let g:terminal_color_0  = s:regal_blue
        let g:terminal_color_1  = s:red
        let g:terminal_color_2  = s:green
        let g:terminal_color_3  = s:yellow
        let g:terminal_color_4  = s:blue
        let g:terminal_color_5  = s:violet
        let g:terminal_color_6  = s:turquoise
        let g:terminal_color_7  = s:white
        let g:terminal_color_8  = s:grey_blue
        let g:terminal_color_9  = s:watermelon
        let g:terminal_color_10 = s:emerald
        let g:terminal_color_11 = s:tan
        let g:terminal_color_12 = s:blue
        let g:terminal_color_13 = s:purple
        let g:terminal_color_14 = s:turquoise
        let g:terminal_color_15 = s:white_blue
    else
        let g:terminal_ansi_colors = [
                    \ s:regal_blue, s:red, s:green, s:yellow,
                    \ s:blue, s:violet, s:turquoise, s:white,
                    \ s:grey_blue, s:watermelon, s:emerald, s:tan,
                    \ s:blue, s:purple, s:turquoise, s:white_blue
                    \]
    endif
endif

" Background and text
if g:nightflyTransparent
    exec 'highlight Normal guibg=NONE' . ' guifg=' . s:white
else
    exec 'highlight Normal guibg=' . s:black . ' guifg=' . s:white
endif

" Custom nightfly highlight groups
exec 'highlight NightflyReset guifg=fg'
exec 'highlight NightflyVisual guibg=' . s:regal_blue
exec 'highlight NightflyWhite guifg=' . s:white
exec 'highlight NightflyDeepBlue guifg=' . s:deep_blue
exec 'highlight NightflySlateBlue guifg=' . s:slate_blue
exec 'highlight NightflyRegalBlue guifg=' . s:regal_blue
exec 'highlight NightflySteelBlue guifg=' . s:steel_blue
exec 'highlight NightflyGreyBlue guifg=' . s:grey_blue
exec 'highlight NightflyCadetBlue guifg=' . s:cadet_blue
exec 'highlight NightflyAshBlue guifg=' . s:ash_blue
exec 'highlight NightflyWhiteBlue guifg=' . s:white_blue
exec 'highlight NightflyYellow guifg=' . s:yellow
exec 'highlight NightflyPeach guifg=' . s:peach
exec 'highlight NightflyTan guifg=' . s:tan
exec 'highlight NightflyOrange guifg=' . s:orange
exec 'highlight NightflyRed guifg=' . s:red
exec 'highlight NightflyWatermelon guifg=' . s:watermelon
exec 'highlight NightflyViolet guifg=' . s:violet
exec 'highlight NightflyPurple guifg=' . s:purple
exec 'highlight NightflyBlue guifg=' . s:blue
exec 'highlight NightflyIndigo guifg=' . s:indigo
exec 'highlight NightflyTurquoise guifg=' . s:turquoise
exec 'highlight NightflyEmerald guifg=' . s:emerald
exec 'highlight NightflyGreen guifg=' . s:green
exec 'highlight NightflyWhiteAlert guibg=bg guifg=' . s:white
exec 'highlight NightflyCadetBlueAlert guibg=bg guifg=' . s:cadet_blue
exec 'highlight NightflyYellowAlert guibg=bg guifg=' . s:yellow
exec 'highlight NightflyOrangeAlert guibg=bg guifg=' . s:orange
exec 'highlight NightflyRedAlert guibg=bg guifg=' . s:red
exec 'highlight NightflyPurpleAlert guibg=bg guifg=' . s:purple
exec 'highlight NightflyBlueAlert guibg=bg guifg=' . s:blue
exec 'highlight NightflyEmeraldAlert guibg=bg guifg=' . s:emerald
exec 'highlight NightflyUnderline gui=underline'
exec 'highlight NightflyNoCombine gui=nocombine'
" Statusline helper colors.
exec 'highlight NightflyBlueMode guibg=' . s:blue . ' guifg=' . s:dark_blue
exec 'highlight NightflyEmeraldMode guibg=' . s:emerald . ' guifg=' . s:dark_blue
exec 'highlight NightflyPurpleMode guibg=' . s:purple . ' guifg=' . s:dark_blue
exec 'highlight NightflyWatermelonMode guibg=' . s:watermelon . ' guifg=' . s:dark_blue
exec 'highlight NightflyTanMode guibg=' . s:tan . ' guifg=' . s:dark_blue
exec 'highlight NightflyTurquoiseMode guibg=' . s:turquoise . ' guifg=' . s:dark_blue
" Tabline helper colors.
exec 'highlight NightflyBlueLine guibg=' . s:slate_blue . ' guifg=' . s:blue
exec 'highlight NightflyBlueLineActive guibg=' . s:regal_blue . '  guifg=' . s:blue
exec 'highlight NightflyCadetBlueLine guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue
exec 'highlight NightflyEmeraldLine guibg=' . s:slate_blue . ' guifg=' . s:emerald
exec 'highlight NightflyEmeraldLineActive guibg=' . s:regal_blue . ' guifg=' . s:emerald
exec 'highlight NightflyGreyBlueLine guibg=' . s:dark_blue . '  guifg=' . s:grey_blue
exec 'highlight NightflyTanLine guibg=' . s:dark_blue . '  guifg=' . s:tan
exec 'highlight NightflyTanLineActive guibg=' . s:regal_blue . '  guifg=' . s:tan
exec 'highlight NightflyWhiteLineActive guibg=' . s:regal_blue . '  guifg=' . s:white_blue

" Color of mode text, -- INSERT --
exec 'highlight ModeMsg guifg=' . s:cadet_blue . ' gui=none'

" Comments
if g:nightflyItalics
    exec 'highlight Comment guifg=' . s:grey_blue . ' gui=italic'
else
    exec 'highlight Comment guifg=' . s:grey_blue
endif

" Functions
highlight! link Function NightflyBlue

" Strings
highlight! link String NightflyTan

" Booleans
highlight! link Boolean NightflyWatermelon

" Identifiers
highlight! link Identifier NightflyTurquoise

" Color of titles
exec 'highlight Title guifg=' . s:orange . ' gui=none'

" const, static
highlight! link StorageClass NightflyOrange

" void, intptr_t
exec 'highlight Type guifg=' . s:emerald . ' gui=none'

" Numbers
highlight! link Constant NightflyOrange

" Character constants
highlight! link Character NightflyPurple

" Exceptions
highlight! link Exception NightflyWatermelon

" ifdef/endif
highlight! link PreProc NightflyWatermelon

" case in switch statement
highlight! link Label NightflyTurquoise

" end-of-line '$', end-of-file '~'
exec 'highlight NonText guifg=' . s:steel_blue . ' gui=none'

" sizeof
highlight! link Operator NightflyWatermelon

" for, while
highlight! link Repeat NightflyViolet

" Search
exec 'highlight Search guibg=bg guifg=' . s:orange . ' gui=reverse'
exec 'highlight IncSearch guibg=bg guifg=' . s:peach

" '\n' sequences
highlight! link Special NightflyWatermelon

" if, else
exec 'highlight Statement guifg=' . s:violet . ' gui=none'

" struct, union, enum, typedef
highlight! link Structure NightflyIndigo

" Statusline, splits and tab lines
exec 'highlight StatusLine cterm=none guibg=' . s:slate_blue . ' guifg=' . s:white . ' gui=none'
exec 'highlight StatusLineNC cterm=none guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue . ' gui=none'
exec 'highlight Tabline cterm=none guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue . ' gui=none'
exec 'highlight TablineSel cterm=none guibg=' . s:dark_blue . ' guifg=' . s:blue . ' gui=none'
exec 'highlight TablineSelSymbol cterm=none guibg=' . s:dark_blue . ' guifg=' . s:emerald . ' gui=none'
exec 'highlight TablineFill cterm=none guibg=' . s:slate_blue . ' guifg=' . s:slate_blue . ' gui=none'
exec 'highlight StatusLineTerm cterm=none guibg=' . s:slate_blue . ' guifg=' . s:white . ' gui=none'
exec 'highlight StatusLineTermNC cterm=none guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue . ' gui=none'
if g:nightflyWinSeparator == 0
    exec 'highlight VertSplit cterm=none guibg=' . s:black . ' guifg=' . s:black . ' gui=none'
elseif g:nightflyWinSeparator == 1
    exec 'highlight VertSplit cterm=none guibg=' . s:slate_blue . ' guifg=' . s:slate_blue . ' gui=none'
else
    exec 'highlight VertSplit guibg=NONE guifg=' . s:slate_blue . ' gui=none'
end

" Visual selection
highlight! link Visual NightflyVisual
exec 'highlight VisualNOS guibg=' . s:regal_blue . ' guifg=fg gui=none'
exec 'highlight VisualInDiff guibg=' . s:regal_blue . ' guifg=' . s:white

" Errors, warnings and whitespace-eol
exec 'highlight Error guibg=bg guifg=' . s:red
exec 'highlight ErrorMsg guibg=bg guifg=' . s:red
exec 'highlight WarningMsg guibg=bg guifg=' . s:orange

" Auto-text-completion menu
exec 'highlight Pmenu guibg=' . s:deep_blue . ' guifg=fg'
exec 'highlight PmenuSel guibg=' . s:cyan_blue . ' guifg=' . s:white_blue
exec 'highlight PmenuSbar guibg=' . s:deep_blue
exec 'highlight PmenuThumb guibg=' . s:steel_blue
exec 'highlight WildMenu guibg=' . s:cyan_blue . ' guifg=' . s:white_blue

" Spelling errors
if g:nightflyUndercurls
    exec 'highlight SpellBad ctermbg=NONE cterm=underline guibg=NONE gui=undercurl guisp=' . s:red
    exec 'highlight SpellCap ctermbg=NONE cterm=underline guibg=NONE gui=undercurl guisp=' . s:blue
    exec 'highlight SpellRare ctermbg=NONE cterm=underline guibg=NONE gui=undercurl guisp=' . s:yellow
    exec 'highlight SpellLocal ctermbg=NONE cterm=underline guibg=NONE gui=undercurl guisp=' . s:blue
else
    exec 'highlight SpellBad ctermbg=NONE cterm=underline guibg=NONE guifg=' . s:red . ' gui=underline guisp=' . s:red
    exec 'highlight SpellCap ctermbg=NONE cterm=underline guibg=NONE guifg=' . s:blue . ' gui=underline guisp=' . s:blue
    exec 'highlight SpellRare ctermbg=NONE cterm=underline guibg=NONE guifg=' . s:yellow . ' gui=underline guisp=' . s:yellow
    exec 'highlight SpellLocal ctermbg=NONE cterm=underline guibg=NONE guifg=' . s:blue . ' gui=underline guisp=' . s:blue
endif

" Misc
exec 'highlight Question guifg=' . s:green . ' gui=none'
exec 'highlight MoreMsg guifg=' . s:red . ' gui=none'
exec 'highlight LineNr guibg=bg guifg=' . s:steel_blue . ' gui=none'
if g:nightflyCursorColor
    exec 'highlight Cursor guifg=bg guibg=' . s:blue
else
    exec 'highlight Cursor guifg=bg guibg=' . s:cadet_blue
endif
exec 'highlight lCursor guifg=bg guibg=' . s:cadet_blue
exec 'highlight CursorLineNr cterm=none guibg=' . s:dark_blue . ' guifg=' . s:blue . ' gui=none'
exec 'highlight CursorColumn guibg=' . s:dark_blue
exec 'highlight CursorLine cterm=none guibg=' . s:dark_blue
exec 'highlight Folded guibg=' . s:dark_blue . ' guifg='. s:green
exec 'highlight FoldColumn guibg=' . s:slate_blue . ' guifg=' . s:green
exec 'highlight SignColumn guibg=bg guifg=' . s:green
exec 'highlight Todo guibg=' . s:yellow . ' guifg=' . s:black
exec 'highlight SpecialKey guibg=bg guifg=' . s:blue
if g:nightflyUnderlineMatchParen
    exec 'highlight MatchParen guibg=bg gui=underline'
else
    highlight! link MatchParen NightflyVisual
endif
exec 'highlight Ignore guifg=' . s:blue
exec 'highlight Underlined guifg=' . s:green . ' gui=none'
exec 'highlight QuickFixLine guibg=' . s:deep_blue
highlight! link Delimiter NightflyWhite
highlight! link qfFileName NightflyEmerald

" Color column (after line 80)
exec 'highlight ColorColumn guibg=' . s:black_blue

" Conceal color
exec 'highlight Conceal guibg=NONE guifg=' . s:ash_blue

" Neovim only highlight groups
if has('nvim')
    exec 'highlight Whitespace guifg=' . s:regal_blue
    exec 'highlight TermCursor guibg=' . s:cadet_blue . ' guifg=bg gui=none'
    if g:nightflyNormalFloat
        exec 'highlight NormalFloat guibg=bg guifg=' . s:cadet_blue
    else
        exec 'highlight NormalFloat guibg=' . s:dark_blue . ' guifg=fg'
    endif
    exec 'highlight FloatBorder guibg=bg guifg=' . s:slate_blue
    exec 'highlight WinBar cterm=none guibg=' . s:deep_blue . ' guifg=' . s:white . ' gui=none'
    exec 'highlight WinBarNC cterm=none guibg=' . s:deep_blue . ' guifg=' . s:cadet_blue . ' gui=none'
    highlight! link WinSeparator VertSplit

    " Neovim Treesitter
    highlight! link TSAnnotation NightflyViolet
    highlight! link TSAttribute NightflyBlue
    highlight! link TSConstant NightflyTurquoise
    highlight! link TSConstBuiltin NightflyGreen
    highlight! link TSConstMacro NightflyViolet
    highlight! link TSConstructor NightflyEmerald
    highlight! link TSFuncBuiltin NightflyBlue
    highlight! link TSFuncMacro NightflyBlue
    highlight! link TSInclude NightflyWatermelon
    highlight! link TSKeywordOperator NightflyViolet
    highlight! link TSNamespace NightflyTurquoise
    highlight! link TSParameter NightflyWhite
    highlight! link TSPunctSpecial NightflyWatermelon
    highlight! link TSSymbol NightflyPurple
    highlight! link TSTag NightflyBlue
    highlight! link TSTagDelimiter NightflyGreen
    highlight! link TSVariableBuiltin NightflyGreen
    highlight! link bashTSParameter NightflyTurquoise
    highlight! link cssTSPunctDelimiter NightflyWatermelon
    highlight! link cssTSType NightflyBlue
    highlight! link scssTSPunctDelimiter NightflyWatermelon
    highlight! link scssTSType NightflyBlue
    highlight! link scssTSVariable NightflyTurquoise
    highlight! link vimTSVariable NightflyTurquoise
    highlight! link yamlTSField NightflyBlue
    highlight! link yamlTSPunctDelimiter NightflyWatermelon
endif

" C/C++
highlight! link cDefine NightflyViolet
highlight! link cPreCondit NightflyViolet
highlight! link cStatement NightflyViolet
highlight! link cStructure NightflyOrange
highlight! link cppAccess NightflyGreen
highlight! link cppCast NightflyTurquoise
highlight! link cppCustomClass NightflyTurquoise
highlight! link cppExceptions NightflyGreen
highlight! link cppModifier NightflyViolet
highlight! link cppOperator NightflyGreen
highlight! link cppSTLconstant NightflyIndigo
highlight! link cppSTLnamespace NightflyIndigo
highlight! link cppStatement NightflyTurquoise
highlight! link cppStructure NightflyViolet

" C#
highlight! link csModifier NightflyGreen
highlight! link csPrecondit NightflyViolet
highlight! link csStorage NightflyViolet
highlight! link csXmlTag NightflyBlue

" Clojure
highlight! link clojureDefine NightflyViolet
highlight! link clojureKeyword NightflyTurquoise
highlight! link clojureMacro NightflyOrange
highlight! link clojureParen NightflyBlue
highlight! link clojureSpecial NightflyViolet

" CoffeeScript
highlight! link coffeeConstant NightflyOrange
highlight! link coffeeGlobal NightflyWatermelon
highlight! link coffeeKeyword NightflyOrange
highlight! link coffeeObject NightflyEmerald
highlight! link coffeeObjAssign NightflyBlue
highlight! link coffeeSpecialIdent NightflyTurquoise
highlight! link coffeeSpecialVar NightflyBlue
highlight! link coffeeStatement NightflyOrange

" Crystal
highlight! link crystalAccess NightflyYellow
highlight! link crystalAttribute NightflyBlue
highlight! link crystalBlockParameter NightflyGreen
highlight! link crystalClass NightflyViolet
highlight! link crystalDefine NightflyViolet
highlight! link crystalExceptional NightflyOrange
highlight! link crystalInstanceVariable NightflyTurquoise
highlight! link crystalModule NightflyBlue
highlight! link crystalPseudoVariable NightflyGreen
highlight! link crystalSharpBang NightflyCadetBlue
highlight! link crystalStringDelimiter NightflyTan
highlight! link crystalSymbol NightflyPurple

" CSS/SCSS
highlight! link cssAtRule NightflyViolet
highlight! link cssAttr NightflyTurquoise
highlight! link cssBraces NightflyReset
highlight! link cssClassName NightflyEmerald
highlight! link cssClassNameDot NightflyViolet
highlight! link cssColor NightflyTurquoise
highlight! link cssIdentifier NightflyBlue
highlight! link cssProp NightflyTurquoise
highlight! link cssTagName NightflyBlue
highlight! link cssUnitDecorators NightflyTan
highlight! link cssValueLength NightflyPurple
highlight! link cssValueNumber NightflyPurple
highlight! link sassId NightflyBlue
highlight! link sassIdChar NightflyViolet
highlight! link sassMedia NightflyViolet
highlight! link scssSelectorName NightflyBlue

" Dart
highlight! link dartMetadata NightflyGreen
highlight! link dartStorageClass NightflyViolet
highlight! link dartTypedef NightflyViolet

" Elixir
highlight! link eelixirDelimiter NightflyWatermelon
highlight! link elixirAtom NightflyPurple
highlight! link elixirBlockDefinition NightflyViolet
highlight! link elixirDefine NightflyViolet
highlight! link elixirDocTest NightflyCadetBlue
highlight! link elixirExUnitAssert NightflyGreen
highlight! link elixirExUnitMacro NightflyBlue
highlight! link elixirKernelFunction NightflyGreen
highlight! link elixirKeyword NightflyOrange
highlight! link elixirModuleDefine NightflyBlue
highlight! link elixirPrivateDefine NightflyViolet
highlight! link elixirStringDelimiter NightflyTan
highlight! link elixirVariable NightflyTurquoise

" Elm
highlight! link elmLetBlockDefinition NightflyGreen
highlight! link elmTopLevelDecl NightflyOrange
highlight! link elmType NightflyBlue

" Go
highlight! link goBuiltins NightflyBlue
highlight! link goConditional NightflyViolet
highlight! link goDeclType NightflyGreen
highlight! link goDirective NightflyWatermelon
highlight! link goFloats NightflyOrange
highlight! link goFunction NightflyBlue
highlight! link goFunctionCall NightflyBlue
highlight! link goImport NightflyWatermelon
highlight! link goLabel NightflyYellow
highlight! link goMethod NightflyBlue
highlight! link goMethodCall NightflyBlue
highlight! link goPackage NightflyViolet
highlight! link goSignedInts NightflyEmerald
highlight! link goStruct NightflyOrange
highlight! link goStructDef NightflyOrange
highlight! link goUnsignedInts NightflyOrange

" Haskell
highlight! link haskellDecl NightflyOrange
highlight! link haskellDeclKeyword NightflyOrange
highlight! link haskellIdentifier NightflyTurquoise
highlight! link haskellLet NightflyBlue
highlight! link haskellOperators NightflyWatermelon
highlight! link haskellType NightflyBlue
highlight! link haskellWhere NightflyViolet

" HTML
highlight! link htmlArg NightflyTurquoise
highlight! link htmlLink NightflyGreen
highlight! link htmlEndTag NightflyPurple
highlight! link htmlH1 NightflyWatermelon
highlight! link htmlH2 NightflyOrange
highlight! link htmlTag NightflyGreen
highlight! link htmlTagN NightflyBlue
highlight! link htmlTagName NightflyBlue
highlight! link htmlUnderline NightflyWhite
if g:nightflyItalics
    exec 'highlight htmlBoldItalic guibg=' . s:black . ' guifg=' . s:orange . ' gui=italic'
    exec 'highlight htmlBoldUnderlineItalic guibg=' . s:black . ' guifg=' . s:orange . ' gui=italic'
    exec 'highlight htmlItalic guifg=' . s:cadet_blue . ' gui=italic'
    exec 'highlight htmlUnderlineItalic guibg=' . s:black . ' guifg=' . s:cadet_blue . ' gui=italic'
else
    exec 'highlight htmlBoldItalic guibg=' . s:black . ' guifg=' . s:orange
    exec 'highlight htmlBoldUnderlineItalic guibg=' . s:black . ' guifg=' . s:orange
    exec 'highlight htmlItalic guifg=' . s:cadet_blue ' gui=none'
    exec 'highlight htmlUnderlineItalic guibg=' . s:black . ' guifg=' . s:cadet_blue
endif

" Java
highlight! link javaAnnotation NightflyGreen
highlight! link javaBraces NightflyWhite
highlight! link javaClassDecl NightflyPeach
highlight! link javaCommentTitle NightflyCadetBlue
highlight! link javaConstant NightflyBlue
highlight! link javaDebug NightflyBlue
highlight! link javaMethodDecl NightflyYellow
highlight! link javaOperator NightflyWatermelon
highlight! link javaScopeDecl NightflyViolet
highlight! link javaStatement NightflyTurquoise

" JavaScript, 'pangloss/vim-javascript' plugin
highlight! link jsClassDefinition NightflyEmerald
highlight! link jsClassKeyword NightflyViolet
highlight! link jsClassMethodType NightflyEmerald
highlight! link jsExceptions NightflyEmerald
highlight! link jsFrom NightflyOrange
highlight! link jsFuncBlock NightflyTurquoise
highlight! link jsFuncCall NightflyBlue
highlight! link jsFunction NightflyViolet
highlight! link jsGlobalObjects NightflyGreen
highlight! link jsModuleAs NightflyOrange
highlight! link jsObjectKey NightflyBlue
highlight! link jsObjectValue NightflyEmerald
highlight! link jsOperator NightflyViolet
highlight! link jsStorageClass NightflyGreen
highlight! link jsTemplateBraces NightflyWatermelon
highlight! link jsTemplateExpression NightflyTurquoise
highlight! link jsThis NightflyTurquoise

" JSX, 'MaxMEllon/vim-jsx-pretty' plugin
highlight! link jsxAttrib NightflyGreen
highlight! link jsxClosePunct NightflyPurple
highlight! link jsxComponentName NightflyBlue
highlight! link jsxOpenPunct NightflyGreen
highlight! link jsxTagName NightflyBlue

" Lua
highlight! link luaBraces NightflyWatermelon
highlight! link luaBuiltin NightflyGreen
highlight! link luaFuncCall NightflyBlue
highlight! link luaSpecialTable NightflyBlue

" Markdown, 'tpope/vim-markdown' plugin
highlight! link markdownBold NightflyPeach
highlight! link markdownCode NightflyTan
highlight! link markdownCodeDelimiter NightflyTan
highlight! link markdownError NormalNC
highlight! link markdownH1 NightflyOrange
highlight! link markdownHeadingRule NightflyBlue
highlight! link markdownItalic NightflyViolet
highlight! link markdownUrl NightflyPurple

" Markdown, 'plasticboy/vim-markdown' plugin
highlight! link mkdDelimiter NightflyWhite
highlight! link mkdLineBreak NormalNC
highlight! link mkdListItem NightflyBlue
highlight! link mkdURL NightflyPurple

" PHP
highlight! link phpClass NightflyEmerald
highlight! link phpClasses NightflyIndigo
highlight! link phpFunction NightflyBlue
highlight! link phpParent NightflyReset
highlight! link phpType NightflyViolet

" PureScript
highlight! link purescriptClass NightflyPeach
highlight! link purescriptModuleParams NightflyOrange

" Python
highlight! link pythonBuiltin NightflyBlue
highlight! link pythonClassVar NightflyGreen
highlight! link pythonCoding NightflyBlue
highlight! link pythonImport NightflyWatermelon
highlight! link pythonOperator NightflyViolet
highlight! link pythonRun NightflyBlue
highlight! link pythonStatement NightflyViolet

" Ruby
highlight! link erubyDelimiter NightflyWatermelon
highlight! link rubyAccess NightflyYellow
highlight! link rubyAssertion NightflyBlue
highlight! link rubyAttribute NightflyBlue
highlight! link rubyBlockParameter NightflyGreen
highlight! link rubyCallback NightflyBlue
highlight! link rubyClassName NightflyEmerald
highlight! link rubyDefine NightflyViolet
highlight! link rubyEntities NightflyBlue
highlight! link rubyExceptional NightflyOrange
highlight! link rubyGemfileMethod NightflyBlue
highlight! link rubyInstanceVariable NightflyTurquoise
highlight! link rubyInterpolationDelimiter NightflyWatermelon
highlight! link rubyMacro NightflyBlue
highlight! link rubyModule NightflyBlue
highlight! link rubyModuleName NightflyEmerald
highlight! link rubyPseudoVariable NightflyGreen
highlight! link rubyResponse NightflyBlue
highlight! link rubyRoute NightflyBlue
highlight! link rubySharpBang NightflyCadetBlue
highlight! link rubyStringDelimiter NightflyTan
highlight! link rubySymbol NightflyPurple

" Rust
highlight! link rustAssert NightflyGreen
highlight! link rustAttribute NightflyReset
highlight! link rustCharacterInvalid NightflyWatermelon
highlight! link rustCharacterInvalidUnicode NightflyWatermelon
highlight! link rustCommentBlockDoc NightflyCadetBlue
highlight! link rustCommentBlockDocError NightflyCadetBlue
highlight! link rustCommentLineDoc NightflyCadetBlue
highlight! link rustCommentLineDocError NightflyCadetBlue
highlight! link rustConstant NightflyOrange
highlight! link rustDerive NightflyGreen
highlight! link rustEscapeError NightflyWatermelon
highlight! link rustFuncName NightflyBlue
highlight! link rustIdentifier NightflyBlue
highlight! link rustInvalidBareKeyword NightflyWatermelon
highlight! link rustKeyword NightflyViolet
highlight! link rustLifetime NightflyViolet
highlight! link rustMacro NightflyGreen
highlight! link rustMacroVariable NightflyViolet
highlight! link rustModPath NightflyIndigo
highlight! link rustObsoleteExternMod NightflyWatermelon
highlight! link rustObsoleteStorage NightflyWatermelon
highlight! link rustReservedKeyword NightflyWatermelon
highlight! link rustSelf NightflyTurquoise
highlight! link rustSigil NightflyTurquoise
highlight! link rustStorage NightflyViolet
highlight! link rustStructure NightflyViolet
highlight! link rustTrait NightflyEmerald
highlight! link rustType NightflyEmerald

" Scala (note, link highlighting does not work, I don't know why)
exec 'highlight scalaCapitalWord guifg=' . s:blue
exec 'highlight scalaCommentCodeBlock guifg=' . s:cadet_blue
exec 'highlight scalaInstanceDeclaration guifg=' . s:turquoise
exec 'highlight scalaKeywordModifier guifg=' . s:green
exec 'highlight scalaSpecial guifg=' . s:watermelon

" Shell scripts
highlight! link shAlias NightflyTurquoise
highlight! link shCommandSub NightflyReset
highlight! link shLoop NightflyViolet
highlight! link shSetList NightflyTurquoise
highlight! link shShellVariables NightflyGreen
highlight! link shVariable NightflyTurquoise

" TypeScript (leafgarland/typescript-vim)
highlight! link typescriptDOMObjects NightflyBlue
highlight! link typescriptFuncComma NightflyWhite
highlight! link typescriptFuncKeyword NightflyGreen
highlight! link typescriptGlobalObjects NightflyBlue
highlight! link typescriptIdentifier NightflyGreen
highlight! link typescriptNull NightflyGreen
highlight! link typescriptOpSymbols NightflyViolet
highlight! link typescriptOperator NightflyWatermelon
highlight! link typescriptParens NightflyWhite
highlight! link typescriptReserved NightflyViolet
highlight! link typescriptStorageClass NightflyGreen

" TypeScript (HerringtonDarkholme/yats.vim)
highlight! link typeScriptModule NightflyBlue
highlight! link typescriptAbstract NightflyOrange
highlight! link typescriptArrayMethod NightflyBlue
highlight! link typescriptArrowFuncArg NightflyWhite
highlight! link typescriptBOM NightflyEmerald
highlight! link typescriptBOMHistoryMethod NightflyBlue
highlight! link typescriptBOMLocationMethod NightflyBlue
highlight! link typescriptBOMWindowProp NightflyGreen
highlight! link typescriptBraces NightflyWhite
highlight! link typescriptCall NightflyWhite
highlight! link typescriptClassHeritage NightflyPeach
highlight! link typescriptClassKeyword NightflyViolet
highlight! link typescriptClassName NightflyEmerald
highlight! link typescriptDecorator NightflyGreen
highlight! link typescriptDOMDocMethod NightflyBlue
highlight! link typescriptDOMEventTargetMethod NightflyBlue
highlight! link typescriptDOMNodeMethod NightflyBlue
highlight! link typescriptExceptions NightflyWatermelon
highlight! link typescriptFuncType NightflyWhite
highlight! link typescriptMathStaticMethod NightflyBlue
highlight! link typescriptMethodAccessor NightflyViolet
highlight! link typescriptObjectLabel NightflyBlue
highlight! link typescriptParamImpl NightflyWhite
highlight! link typescriptStringMethod NightflyBlue
highlight! link typescriptTry NightflyWatermelon
highlight! link typescriptVariable NightflyGreen
highlight! link typescriptXHRMethod NightflyBlue

" Vimscript
highlight! link vimBracket NightflyBlue
highlight! link vimCommand NightflyViolet
highlight! link vimCommentTitle NightflyViolet
highlight! link vimEnvvar NightflyWatermelon
highlight! link vimFuncName NightflyBlue
highlight! link vimFuncSID NightflyBlue
highlight! link vimFunction NightflyBlue
highlight! link vimHighlight NightflyBlue
highlight! link vimNotFunc NightflyViolet
highlight! link vimNotation NightflyBlue
highlight! link vimOption NightflyTurquoise
highlight! link vimParenSep NightflyWhite
highlight! link vimSep NightflyWhite
highlight! link vimUserFunc NightflyBlue

" XML
highlight! link xmlAttrib NightflyGreen
highlight! link xmlEndTag NightflyBlue
highlight! link xmlTag NightflyGreen
highlight! link xmlTagName NightflyBlue

" Git commits
highlight! link gitCommitBranch NightflyBlue
highlight! link gitCommitDiscardedFile NightflyWatermelon
highlight! link gitCommitDiscardedType NightflyBlue
highlight! link gitCommitHeader NightflyPurple
highlight! link gitCommitSelectedFile NightflyEmerald
highlight! link gitCommitSelectedType NightflyBlue
highlight! link gitCommitUntrackedFile NightflyWatermelon
highlight! link gitEmail NightflyBlue

" Git commit diffs
highlight! link diffAdded NightflyGreen
highlight! link diffChanged NightflyWatermelon
highlight! link diffIndexLine NightflyWatermelon
highlight! link diffLine NightflyBlue
highlight! link diffRemoved NightflyRed
highlight! link diffSubname NightflyBlue

" Tagbar plugin
highlight! link TagbarFoldIcon NightflyCadetBlue
highlight! link TagbarVisibilityPublic NightflyGreen
highlight! link TagbarVisibilityProtected NightflyGreen
highlight! link TagbarVisibilityPrivate NightflyGreen
highlight! link TagbarKind NightflyEmerald

" NERDTree plugin
highlight! link NERDTreeClosable NightflyEmerald
highlight! link NERDTreeCWD NightflyPurple
highlight! link NERDTreeDir NightflyBlue
highlight! link NERDTreeDirSlash NightflyWatermelon
highlight! link NERDTreeExecFile NightflyTan
highlight! link NERDTreeFile NightflyWhite
highlight! link NERDTreeFlags NightflyPurple
highlight! link NERDTreeHelp NightflyCadetBlue
highlight! link NERDTreeLinkDir NightflyBlue
highlight! link NERDTreeLinkFile NightflyBlue
highlight! link NERDTreeLinkTarget NightflyTurquoise
highlight! link NERDTreeOpenable NightflyEmerald
highlight! link NERDTreePart NightflyRegalBlue
highlight! link NERDTreePartFile NightflyRegalBlue
highlight! link NERDTreeUp NightflyBlue

" NERDTree Git plugin
highlight! link NERDTreeGitStatusDirDirty NightflyTan
highlight! link NERDTreeGitStatusModified NightflyWatermelon
highlight! link NERDTreeGitStatusRenamed NightflyBlue
highlight! link NERDTreeGitStatusStaged NightflyBlue
highlight! link NERDTreeGitStatusUntracked NightflyRed

" fern.vim plugin
highlight! link FernBranchSymbol NightflyEmerald
highlight! link FernBranchText NightflyBlue
highlight! link FernMarkedLine NightflyVisual
highlight! link FernMarkedText NightflyWatermelon
highlight! link FernRootSymbol NightflyPurple
highlight! link FernRootText NightflyPurple

" fern-git-status.vim plugin
highlight! link FernGitStatusBracket NightflyGreyBlue
highlight! link FernGitStatusIndex NightflyEmerald
highlight! link FernGitStatusWorktree NightflyWatermelon

" Glyph palette
highlight! link GlyphPalette1 NightflyWatermelon
highlight! link GlyphPalette2 NightflyEmerald
highlight! link GlyphPalette3 NightflyYellow
highlight! link GlyphPalette4 NightflyBlue
highlight! link GlyphPalette6 NightflyTurquoise
highlight! link GlyphPalette7 NightflyWhite
highlight! link GlyphPalette9 NightflyWatermelon

" Misc languages and plugins
highlight! link bufExplorerHelp NightflyCadetBlue
highlight! link bufExplorerSortBy NightflyCadetBlue
highlight! link CleverFDefaultLabel NightflyWatermelon
highlight! link CtrlPMatch NightflyOrange
highlight! link Directory NightflyBlue
highlight! link HighlightedyankRegion NightflyRegalBlue
highlight! link jsonKeyword NightflyBlue
highlight! link jsonBoolean NightflyTurquoise
highlight! link jsonQuote NightflyWhite
highlight! link netrwClassify NightflyWatermelon
highlight! link netrwDir NightflyBlue
highlight! link netrwExe NightflyTan
highlight! link tagName NightflyTurquoise
highlight! link Cheat40Header NightflyBlue
highlight! link yamlBlockMappingKey NightflyBlue
highlight! link yamlFlowMappingKey NightflyBlue
if g:nightflyUnderlineMatchParen
    exec 'highlight MatchWord gui=underline guisp=' . s:orange
else
    highlight! link highlight NightflyOrange
endif
exec 'highlight snipLeadingSpaces guibg=bg guifg=fg'
exec 'highlight MatchWordCur guibg=bg'

" vimdiff/nvim -d
exec 'highlight DiffAdd guibg=' . s:emerald . ' guifg=' . s:black
exec 'highlight DiffChange guibg=' . s:slate_blue
exec 'highlight DiffDelete guibg=' . s:slate_blue . ' guifg=' . s:watermelon ' gui=none'
exec 'highlight DiffText guibg=' . s:blue . ' guifg=' . s:black . ' gui=none'

" ALE plugin
if g:nightflyUndercurls
    exec 'highlight ALEError guibg=NONE gui=undercurl guisp=' . s:red
    exec 'highlight ALEWarning guibg=NONE gui=undercurl guisp=' . s:yellow
    exec 'highlight ALEInfo guibg=NONE gui=undercurl guisp=' . s:blue
else
    exec 'highlight ALEError guibg=NONE'
    exec 'highlight ALEWarning guibg=NONE'
    exec 'highlight ALEInfo guibg=NONE'
endif
highlight! link ALEVirtualTextError NightflySteelBlue
highlight! link ALEErrorSign NightflyRedAlert
highlight! link ALEVirtualTextWarning NightflySteelBlue
highlight! link ALEWarningSign NightflyYellowAlert
highlight! link ALEVirtualTextInfo NightflySteelBlue
highlight! link ALEInfoSign NightflyBlueAlert

" GitGutter plugin
highlight! link GitGutterAdd NightflyEmeraldAlert
highlight! link GitGutterChange NightflyYellowAlert
highlight! link GitGutterChangeDelete NightflyOrangeAlert
highlight! link GitGutterDelete NightflyRedAlert

" Signify plugin
highlight! link SignifySignAdd NightflyEmeraldAlert
highlight! link SignifySignChange NightflyYellowAlert
highlight! link SignifySignDelete NightflyRedAlert

" FZF plugin
exec 'highlight fzf1 guifg=' . s:watermelon . ' guibg=' . s:slate_blue
exec 'highlight fzf2 guifg=' . s:blue . ' guibg=' . s:slate_blue
exec 'highlight fzf3 guifg=' . s:green . ' guibg=' . s:slate_blue
exec 'highlight fzfNormal guifg=' . s:ash_blue
exec 'highlight fzfFgPlus guifg=' . s:white_blue
exec 'highlight fzfBorder guifg=' . s:slate_blue
let g:fzf_colors = {
  \  'fg':      ['fg', 'fzfNormal'],
  \  'bg':      ['bg', 'Normal'],
  \  'hl':      ['fg', 'Number'],
  \  'fg+':     ['fg', 'fzfFgPlus'],
  \  'bg+':     ['bg', 'Pmenu'],
  \  'hl+':     ['fg', 'Number'],
  \  'info':    ['fg', 'String'],
  \  'border':  ['fg', 'fzfBorder'],
  \  'prompt':  ['fg', 'fzf2'],
  \  'pointer': ['fg', 'Exception'],
  \  'marker':  ['fg', 'StorageClass'],
  \  'spinner': ['fg', 'Type'],
  \  'header':  ['fg', 'CursorLineNr']
  \}

" mistfly-statusline plugin
highlight! link MistflyNormal NightflyBlueMode
highlight! link MistflyInsert NightflyEmeraldMode
highlight! link MistflyVisual NightflyPurpleMode
highlight! link MistflyCommand NightflyTanMode
highlight! link MistflyReplace NightflyWatermelonMode

" Coc plugin (see issue: https://github.com/bluz71/vim-nightfly-guicolors/issues/31)
highlight! link CocUnusedHighlight NightflyAshBlue

" indentLine plugin
if !exists('g:indentLine_defaultGroup') && !exists('g:indentLine_color_gui')
    let g:indentLine_color_gui = s:deep_blue
endif

" Neovim diagnostics
if has('nvim-0.6')
    " Neovim 0.6 diagnostic
    highlight! link DiagnosticError NightflyRed
    highlight! link DiagnosticWarn NightflyYellow
        highlight! link DiagnosticInfo NightflyBlue
    highlight! link DiagnosticHint NightflyWhite
    if g:nightflyUndercurls
        exec 'highlight DiagnosticUnderlineError guibg=NONE gui=undercurl guisp=' . s:red
        exec 'highlight DiagnosticUnderlineWarn guibg=NONE gui=undercurl guisp=' . s:yellow
        exec 'highlight DiagnosticUnderlineInfo guibg=NONE gui=undercurl guisp=' . s:blue
        exec 'highlight DiagnosticUnderlineHint guibg=NONE gui=undercurl guisp=' . s:white
    else
        exec 'highlight DiagnosticUnderlineError guibg=NONE gui=underline guisp=' . s:red
        exec 'highlight DiagnosticUnderlineWarn guibg=NONE gui=underline guisp=' . s:yellow
        exec 'highlight DiagnosticUnderlineInfo guibg=NONE gui=underline guisp=' . s:blue
        exec 'highlight DiagnosticUnderlineHint guibg=NONE gui=underline guisp=' . s:white
    endif
    highlight! link DiagnosticVirtualTextError NightflySteelBlue
    highlight! link DiagnosticVirtualTextWarn NightflySteelBlue
    highlight! link DiagnosticVirtualTextInfo NightflySteelBlue
    highlight! link DiagnosticVirtualTextHint NightflySteelBlue
    highlight! link DiagnosticSignError NightflyRedAlert
    highlight! link DiagnosticSignWarn NightflyYellowAlert
    highlight! link DiagnosticSignInfo NightflyBlueAlert
    highlight! link DiagnosticSignHint NightflyWhiteAlert
    highlight! link DiagnosticFloatingError NightflyRed
    highlight! link DiagnosticFloatingWarn NightflyYellow
    highlight! link DiagnosticFloatingInfo NightflyBlue
    highlight! link DiagnosticFloatingHint NightflyWhite
    highlight! link LspSignatureActiveParameter NightflyVisual
elseif has('nvim-0.5')
    " Neovim 0.5 LSP diagnostics
    if g:nightflyUndercurls
        exec 'highlight LspDiagnosticsUnderlineError guibg=NONE gui=undercurl guisp=' . s:red
        exec 'highlight LspDiagnosticsUnderlineWarning guibg=NONE gui=undercurl guisp=' . s:yellow
        exec 'highlight LspDiagnosticsUnderlineInformation guibg=NONE gui=undercurl guisp=' . s:blue
        exec 'highlight LspDiagnosticsUnderlineHint guibg=NONE gui=undercurl guisp=' . s:white
    else
        exec 'highlight LspDiagnosticsUnderlineError guibg=NONE gui=underline guisp=' . s:red
        exec 'highlight LspDiagnosticsUnderlineWarning guibg=NONE gui=underline guisp=' . s:yellow
        exec 'highlight LspDiagnosticsUnderlineInformation guibg=NONE gui=underline guisp=' . s:blue
        exec 'highlight LspDiagnosticsUnderlineHint guibg=NONE gui=underline guisp=' . s:white
    endif
    highlight! link LspDiagnosticsVirtualTextError NightflySteelBlue
    highlight! link LspDiagnosticsVirtualTextWarning NightflySteelBlue
    highlight! link LspDiagnosticsVirtualTextInformation NightflySteelBlue
    highlight! link LspDiagnosticsVirtualTextHint NightflySteelBlue
    highlight! link LspDiagnosticsSignError NightflyRedAlert
    highlight! link LspDiagnosticsSignWarning NightflyYellowAlert
    highlight! link LspDiagnosticsSignInformation NightflyBlueAlert
    highlight! link LspDiagnosticsSignHint NightflyWhiteAlert
    highlight! link LspDiagnosticsFloatingError NightflyRed
    highlight! link LspDiagnosticsFloatingWarning NightflyYellow
    highlight! link LspDiagnosticsFloatingInformation NightflyBlue
    highlight! link LspDiagnosticsFloatingHint NightflyWhite
    highlight! link LspSignatureActiveParameter NightflyVisual
endif

" Neovim only plugins
if has('nvim')
    " NvimTree plugin
    highlight! link NvimTreeFolderIcon NightflyBlue
    highlight! link NvimTreeFolderName NightflyBlue
    highlight! link NvimTreeIndentMarker NightflySlateBlue
    highlight! link NvimTreeOpenedFolderName NightflyBlue
    highlight! link NvimTreeRootFolder NightflyPurple
    highlight! link NvimTreeSpecialFile NightflyYellow
    highlight! link NvimTreeWindowPicker DiffChange
    exec 'highlight NvimTreeExecFile guifg=' . s:green . ' gui=none'
    exec 'highlight NvimTreeImageFile guifg=' . s:violet . ' gui=none'
    exec 'highlight NvimTreeOpenedFile guifg=' . s:yellow . ' gui=none'
    exec 'highlight NvimTreeSymlink guifg=' . s:turquoise . ' gui=none'

    " Neo-tree plugin
    highlight! link NeoTreeDimText NightflyDeepBlue
    highlight! link NeoTreeDotfile NightflySlateBlue
    highlight! link NeoTreeGitConflict NightflyWatermelon
    highlight! link NeoTreeGitModified NightflyViolet
    highlight! link NeoTreeGitUntracked NightflySteelBlue
    highlight! link NeoTreeMessage NightflyCadetBlue
    highlight! link NeoTreeModified NightflyYellow
    highlight! link NeoTreeRootName NightflyPurple

    " Telescope plugin
    highlight! link TelescopeBorder NightflySlateBlue
    highlight! link TelescopeMatching NightflyOrange
    highlight! link TelescopeMultiSelection NightflyWatermelon
    highlight! link TelescopeNormal NightflyAshBlue
    highlight! link TelescopePreviewDate NightflyGreyBlue
    highlight! link TelescopePreviewGroup NightflyGreyBlue
    highlight! link TelescopePreviewLink NightflyTurquoise
    highlight! link TelescopePreviewMatch NightflyVisual
    highlight! link TelescopePreviewRead NightflyOrange
    highlight! link TelescopePreviewSize NightflyEmerald
    highlight! link TelescopePreviewUser NightflyGreyBlue
    highlight! link TelescopePromptPrefix NightflyBlue
    highlight! link TelescopeResultsDiffAdd NightflyGreen
    highlight! link TelescopeResultsDiffChange NightflyRed
    highlight! link TelescopeResultsSpecialComment NightflySteelBlue
    highlight! link TelescopeSelectionCaret NightflyWatermelon
    highlight! link TelescopeTitle NightflySteelBlue
    exec 'highlight TelescopeSelection guibg=' . s:regal_blue . ' guifg=' . s:white_blue

    " gitsigns.nvim plugin
    highlight! link GitSignsAdd NightflyEmeraldAlert
    highlight! link GitSignsAddLn NightflyGreen
    highlight! link GitSignsChange NightflyYellowAlert
    highlight! link GitSignsChangeDelete NightflyOrangeAlert
    highlight! link GitSignsChangeLn NightflyYellow
    highlight! link GitSignsChangeNr NightflyYellowAlert
    highlight! link GitSignsDelete NightflyRedAlert
    highlight! link GitSignsDeleteLn NightflyRed
    exec 'highlight GitSignsAddInline guibg=' . s:green . ' guifg=' . s:black
    exec 'highlight GitSignsChangeInline guibg=' . s:yellow . ' guifg=' . s:black
    exec 'highlight GitSignsDeleteInline guibg=' . s:red . ' guifg=' . s:black

    " Hop plugin
    highlight! link HopCursor IncSearch
    highlight! link HopNextKey NightflyYellow
    highlight! link HopNextKey1 NightflyBlue
    highlight! link HopNextKey2 NightflyWatermelon
    highlight! link HopUnmatched NightflyGreyBlue

    " Barbar plugin
    highlight! link BufferCurrent NightflyWhiteLineActive
    highlight! link BufferCurrentIndex NightflyWhiteLineActive
    highlight! link BufferCurrentMod NightflyTanLineActive
    highlight! link BufferTabpages NightflyBlueLine
    highlight! link BufferVisible NightflyGreyBlueLine
    highlight! link BufferVisibleIndex NightflyGreyBlueLine
    highlight! link BufferVisibleMod NightflyTanLine
    highlight! link BufferVisibleSign NightflyGreyBlueLine
    exec 'highlight BufferCurrentSign  guibg=' . s:regal_blue . '  guifg=' . s:blue
    exec 'highlight BufferInactive     guibg=' . s:slate_blue . ' guifg=' . s:grey_blue
    exec 'highlight BufferInactiveMod  guibg=' . s:slate_blue . ' guifg=' . s:tan
    exec 'highlight BufferInactiveSign guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue

    " Bufferline plugin
    exec 'highlight BufferLineFill guibg=bg guifg=bg'
    highlight! link BufferLineBackground NightflyGreyBlueLine
    highlight! link BufferLineBuffer BufferLineBackground
    highlight! link BufferLineBufferSelected NightflyWhiteLineActive
    highlight! link BufferLineBufferVisible NightflyCadetBlueLine
    highlight! link BufferLineCloseButton BufferLineBackground
    highlight! link BufferLineCloseButtonSelected NightflyBlueLineActive
    highlight! link BufferLineCloseButtonVisible NightflyCadetBlueLine
    highlight! link BufferLineIndicatorSelected NightflyBlueLineActive
    highlight! link BufferLineIndicatorVisible NightflyCadetBlueLine
    highlight! link BufferLineModified BufferLineBackground
    highlight! link BufferLineModifiedSelected NightflyEmeraldLineActive
    highlight! link BufferLineModifiedVisible NightflyEmeraldLine
    highlight! link BufferLineSeparator BufferLineFill
    highlight! link BufferLineSeparatorSelected BufferLineFill
    highlight! link BufferLineTab BufferLineBackground
    highlight! link BufferLineTabClose NightflyBlueLine
    highlight! link BufferLineTabSelected NightflyBlueLineActive

    " nvim-cmp plugin
    highlight! link CmpItemAbbrMatch NightflyTan
    highlight! link CmpItemAbbrMatchFuzzy NightflyOrange
    highlight! link CmpItemKind NightflyWhite
    highlight! link CmpItemKindClass NightflyEmerald
    highlight! link CmpItemKindColor NightflyTurquoise
    highlight! link CmpItemKindConstant NightflyPurple
    highlight! link CmpItemKindConstructor NightflyBlue
    highlight! link CmpItemKindEnum NightflyViolet
    highlight! link CmpItemKindEnumMember NightflyTurquoise
    highlight! link CmpItemKindEvent NightflyViolet
    highlight! link CmpItemKindField NightflyTurquoise
    highlight! link CmpItemKindFile NightflyBlue
    highlight! link CmpItemKindFolder NightflyBlue
    highlight! link CmpItemKindFunction NightflyBlue
    highlight! link CmpItemKindInterface NightflyEmerald
    highlight! link CmpItemKindKeyword NightflyViolet
    highlight! link CmpItemKindMethod NightflyBlue
    highlight! link CmpItemKindModule NightflyEmerald
    highlight! link CmpItemKindOperator NightflyViolet
    highlight! link CmpItemKindProperty NightflyTurquoise
    highlight! link CmpItemKindReference NightflyTurquoise
    highlight! link CmpItemKindSnippet NightflyGreen
    highlight! link CmpItemKindStruct NightflyEmerald
    highlight! link CmpItemKindText NightflyAshBlue
    highlight! link CmpItemKindTypeParameter NightflyEmerald
    highlight! link CmpItemKindUnit NightflyTurquoise
    highlight! link CmpItemKindValue NightflyTurquoise
    highlight! link CmpItemKindVariable NightflyTurquoise
    highlight! link CmpItemMenu NightflyCadetBlue

    " Indent Blankline plugin
    exec 'highlight IndentBlanklineChar guifg=' . s:deep_blue  . ' gui=nocombine'
    exec 'highlight IndentBlanklineSpaceChar guifg=' . s:deep_blue  . ' gui=nocombine'
    exec 'highlight IndentBlanklineSpaceCharBlankline guifg=' . s:deep_blue  . ' gui=nocombine'

    " Mini.nvim plugin
    highlight! link MiniCompletionActiveParameter NightflyVisual
    highlight! link MiniCursorword NightflyUnderline
    highlight! link MiniCursorwordCurrent NightflyUnderline
    highlight! link MiniIndentscopePrefix NightflyNoCombine
    highlight! link MiniIndentscopeSymbol NightflyWhite
    highlight! link MiniJump SpellRare
    highlight! link MiniStarterCurrent NightflyNoCombine
    highlight! link MiniStarterFooter Title
    highlight! link MiniStarterHeader NightflyViolet
    highlight! link MiniStarterInactive Comment
    highlight! link MiniStarterItem Normal
    highlight! link MiniStarterItemBullet Delimiter
    highlight! link MiniStarterItemPrefix NightflyYellow
    highlight! link MiniStarterQuery NightflyBlue
    highlight! link MiniStarterSection NightflyWatermelon
    highlight! link MiniStatuslineDevinfo NightflyVisual
    highlight! link MiniStatuslineFileinfo NightflyVisual
    highlight! link MiniStatuslineModeCommand NightflyTanMode
    highlight! link MiniStatuslineModeInsert NightflyEmeraldMode
    highlight! link MiniStatuslineModeNormal NightflyBlueMode
    highlight! link MiniStatuslineModeOther NightflyTurquoiseMode
    highlight! link MiniStatuslineModeReplace NightflyWatermelonMode
    highlight! link MiniStatuslineModeVisual NightflyPurpleMode
    highlight! link MiniSurround IncSearch
    highlight! link MiniTablineCurrent NightflyWhiteLineActive
    highlight! link MiniTablineFill TabLineFill
    highlight! link MiniTablineModifiedCurrent NightflyTanLineActive
    highlight! link MiniTablineModifiedVisible NightflyTanLine
    highlight! link MiniTablineTabpagesection NightflyBlueMode
    highlight! link MiniTablineVisible NightflyGreyBlueLine
    highlight! link MiniTestEmphasis NightflyUnderline
    highlight! link MiniTestFail NightflyRed
    highlight! link MiniTestPass NightflyGreen
    highlight! link MiniTrailspace NightflyWatermelonMode
    exec 'highlight MiniJump2dSpot guifg=' . s:yellow . ' gui=underline,nocombine'
    exec 'highlight MiniStatuslineFilename guibg=' . s:slate_blue . ' guifg=' . s:white
    exec 'highlight MiniStatuslineInactive guibg=' . s:slate_blue . ' guifg=' . s:cadet_blue
    exec 'highlight MiniTablineHidden guibg=' . s:slate_blue . ' guifg=' . s:grey_blue
    exec 'highlight MiniTablineModifiedHidden guibg=' . s:slate_blue . ' guifg=' . s:tan

    " Dashboard plugin
    highlight! link DashboardCenter NightflyViolet
    highlight! link DashboardFooter NightflyOrange
    highlight! link DashboardHeader NightflyBlue
    highlight! link DashboardShortCut NightflyTurquoise
endif


highlight Cursorline cterm=bold
