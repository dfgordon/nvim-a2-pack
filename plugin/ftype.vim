" For some reason .s cannot be handled by Lua. "
" So we may as well put all the filetypes here. "
" Also, we find case sensitivity in some scenarios. "
au BufRead,BufNewFile *.s     set filetype=merlin
au BufRead,BufNewFile *.S     set filetype=merlin
au BufRead,BufNewFile *.asm   set filetype=merlin
au BufRead,BufNewFile *.ASM   set filetype=merlin
au BufRead,BufNewFile *.bas   set filetype=applesoft
au BufRead,BufNewFile *.BAS   set filetype=applesoft
au BufRead,BufNewFile *.abas  set filetype=applesoft
au BufRead,BufNewFile *.ibas  set filetype=integerbasic