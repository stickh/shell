set ignorecase          " 搜索不区分大小写
set incsearch           " 递进搜索
set hlsearch		" ..
set nu                  " 设置行号
set autoindent          " 自动缩进
set cindent             " 自动缩进
set cursorline          " 设置下划线
set cursorcolumn 	" 当前列高亮
set nobackup            " 禁止生成备份
set noswapfile          " 禁止生成临时文件
"  #############################################################


:inoremap < <><ESC>i
:inoremap > <c-r>=ClosePair(' > ' )
:inoremap ( ()<ESC>i
:inoremap ) <c-r>=ClosePair(' ) ' )<CR>
:inoremap { {<CR>}<ESC>O
:inoremap } <c-r>=ClosePair(' } ' )<CR>
:inoremap [ []<ESC>i
:inoremap ] <c-r>=ClosePair(' ] ' )<CR>
:inoremap "   ""<ESC>i
:inoremap '   ''<ESC>i

function! ClosePair(char )
	 if  getline(' . ' )[col(' . ' ) - 1 ] == a:char
		return  " \<Right> "
	 else
		return  a:char
	 endif
endfunction

filetype plugin indent on
" 打开文件类型检测,加了这句才可以用智能补全
