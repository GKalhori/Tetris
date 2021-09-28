.model small
.stack 64   
.data
    
    ; borders coordinate
    brd_ul dw 57, 141
    brd_ur dw 61, 181
    brd_dl dw 117, 137
    brd_dr dw 121, 177
    
    ; drawing bounds 	
    start_col dw ?
    end_col dw ?
    rst_col dw ?
    start_row dw ?    
    end_row dw ?   
    
    ; shift bounds
    srch_str_col dw 141
    srch_end_col dw 177
    
    ; features of pieces
    curr_shape db ?     ; T, Z, L, S, R
    curr_ang dw ?       ; 0, 90, 180, 270
    curr_color db ?   
     
    ; messages
    game_over_msg db 'G','A','M','E',' ','O','V','E','R','$'
    score_msg db "SCORE: $"
    left_msg dw "A - Left$"
    right_msg dw "D - Right$"
    fast_msg dw "F - Fast$"
    down_msg dw "S - Down$"
    rotate_msg dw "W - Rotate$"
    
    ; others
    down_blockd db 1        
    score dw 0
    char db ?
    full_rows_num dw 0
    curr_row dw ?
    ten dw 10
    
;\--------------------------------------------------------------------------/
;|                                 Main                                     |
;/--------------------------------------------------------------------------\
    
.code
#start=led_display.exe# 

main proc far    
    ; set data stack
    mov ax, @data
	mov ds, ax
	
	; reset led    
    mov ax, 0
    out 199, ax
    	
    ; set graphical mode 320*200
    mov ah, 0
    mov al, 13h
    int 10h    
    
    ; start game        
    call game_border        ; initial game borders
    call show_score         ; initial player score
         
    generate_piece:         ; initial game piece                 
        call check_full     ; check full rows related to the last piece                                 
        
        mov dx, 61          ; check if the first row is blockd
        mov cx, 157              
        mov ah, 0Dh         ; get color of the block
        int 10h 
        cmp al, 0           ; if al!=black        
        jnz call game_over
        
        mov down_blockd, 1 ; reset        
        call get_rand       ; dl=> 0(T), 1(L), 2(R), 3(S), 4(Z)
                    
        cmp dl,0            ; case T
        jnz next_rand2
                        
            mov start_row, 61
            mov start_col, 157
            mov curr_shape, 't'
            mov curr_color, 05h     ; color = purple
            call draw_t
            jmp continue
        
        next_rand2:     
            cmp dl,1        ; case L
            jnz next_rand3
            
            mov start_row, 61
            mov start_col, 157
            mov curr_shape, 'l'
            mov curr_color, 0Ch     ; color = orange
            call draw_l
            jmp continue
            
        next_rand3:
            cmp dl,2        ; case Line 
            jnz next_rand4
            
            mov start_row, 61
            mov start_col, 153
            mov curr_shape, 'r'
            mov curr_color, 0Bh     ; color = light blue 
            call draw_line
            jmp continue
            
        next_rand4:
            cmp dl,3        ; case Square
            jnz next_rand5
            
            mov start_row, 61
            mov start_col, 157
            mov curr_shape, 's'
            mov curr_color, 0Eh      ; color = yellow
            call draw_square
            jmp continue
            
        next_rand5:         ; case Z
            mov start_row, 61
            mov start_col, 157
            mov curr_shape, 'z'
            mov curr_color, 0Ah     ; color = green
            call draw_z

                      
    continue:
        call check_down        
        cmp down_blockd, 1 ; if down way is blockd (0) generate new piece
        jnz generate_piece
        call get_input      ; get new keyboard input                                                                         
        jmp continue        ; else
    
    ret                                  
main endp 

;\--------------------------------------------------------------------------/
;|                             Keyboard Input                               |
;/--------------------------------------------------------------------------\

get_input proc
    invalid_input:   
        mov ah, 01h      ; check keyboard buffer
        int 16h
        jnz clear_buffer ; buffer is not empty    
    
        call delay	 
        call delay
        call delay
        call delay
		call move_down
		jmp input_done

        clear_buffer:
        mov ah, 00h    ; clear buffer
        int 16h	
        mov char, al   ; switch case (char)     
                                 
        cmp char,'s'
        jnz next_char
        call move_down    
        jmp input_done
    
    next_char:
        cmp char,'a'
        jnz next_char2
        call move_left 
        jmp input_done
    
    next_char2:
        cmp char,'d'
        jnz next_char3
        call move_right
        jmp input_done
   
    next_char3:
        cmp char,'w'
        jnz next_char4 
        call rotate   
        jmp input_done 
       
    next_char4:
        cmp char,'f'
        jnz invalid_input 
        call fast_down
            
    input_done:
    ret
get_input endp

;\--------------------------------------------------------------------------/
;|                                 Show Score                               |
;/--------------------------------------------------------------------------\

show_score proc           
    ; convert score to digits
    mov si, 0
    mov ax, score
    convert:
        mov  dx, 0   ; reset     
        div ten       
        push dx      ; remainder
        inc si
        cmp ax,0     ; quotient
        jnz convert        
               
    ; print "SCORE: " 
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 5        ; row
    mov dl, 16       ; column
    int 10h    
    mov ah, 09h      ; output of a string
    lea dx, score_msg
    int 21h
         
   ;print score digits
   print_score:     
        pop dx
        add dl, 30h  ; convert int to char
        mov ah, 02h  ; print char
        int 21h
        dec si
        cmp si,0
        jnz print_score
    
    ;show score on led
    mov ax, score
    out 199, ax   
    
    ret
show_score endp

;\--------------------------------------------------------------------------/
;|                               Game Border                                |
;/--------------------------------------------------------------------------\

game_border proc
    mov al,0Fh  ; set white color
    
    ; top line          
	mov cx,[brd_ul+2]
	mov dx,brd_ul	   	   	   
	top_border: 
	    call draw_tile
	   	mov cx,[brd_ul+2]
	    mov dx,brd_ul
	    add si,4
	    add cx,si	   	        
        cmp cx,[brd_ur+2]
        jnz top_border
      
    ; right line   
    mov si,0      
    mov cx,[brd_ur+2]
    mov dx,brd_ur	   	   	   
	right_border: 
	    call draw_tile
	   	mov cx,[brd_ur+2]
	    mov dx,brd_ur
	    add si,4
	    add dx,si	   	        
        cmp dx,brd_dr
        jnz right_border
      
    ; bottom line        
    mov si,0
	mov cx,[brd_dr+2]
	mov dx,brd_dr	   	   	   
	bottom_border: 
	     call draw_tile
	   	 mov cx,[brd_dr+2]
	     mov dx,brd_dr
	     add si,4
	     sub cx,si	   	        
         cmp cx,[brd_dl+2]
         jnz bottom_border
       
    ; left line   
    mov si,0      
    mov cx,[brd_dl+2]
	mov dx,brd_dl	   	   	   
    left_border: 
	    call draw_tile
	   	mov cx,[brd_dl+2]
	    mov dx,brd_dl
	    add si,4
	    sub dx,si	   	        
        cmp dx,brd_ul
        jnz left_border 
    
    ; guide of D
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 7        ; row
    mov dl, 6        ; column
    int 10h    
    mov ah, 09h      ; output of a string
    lea dx, right_msg
    int 21h
      
    ; guide of A  
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 9        ; row
    mov dl, 6        ; column
    int 10h    
    mov ah, 09h      ; output of a string
    lea dx, left_msg
    int 21h
      
    ; guide of S    
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 11       ; row
    mov dl, 6        ; column
    int 10h    
    mov ah, 09h      ; output of a string
    lea dx, down_msg
    int 21h
         
    ; guide of F     
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 13       ; row
    mov dl, 6        ; column
    int 10h    
    mov ah, 09h      ; output of a string
    lea dx, fast_msg
    int 21h
    
    ; guide of W 
    mov ah, 02h      ; set cursor position
    mov bh, 00       ; page number
    mov dh, 15       ; row
    mov dl, 6        ; column
    int 10h          
    mov ah, 09h      ; output of a string
    lea dx, rotate_msg
    int 21h 
    
    ret            
game_border endp 

;\--------------------------------------------------------------------------/
;|                              Game Over                                   |
;/--------------------------------------------------------------------------\

game_over proc        
    mov si, offset game_over_msg ; load game over message    
    mov dl, 16          ; col
    mov dh, 11          ; row
         
    set_cursor:           
        mov ah, 2 
        mov bh, 0 
        int 10h
             
    while:          
        mov al, [si]  
        cmp al, '$'     ; end of string
        je finish 
        
        mov  ah, 9      ; print char interrupt
        mov  bh, 0
        mov  bl, 04h    ; red color
        mov  cx, 1      ; times to display char 
        int  10h
          
        inc si          ; next char        
        inc dl          ; next col         
        jmp set_cursor        
        
    finish:    
    mov ah, 4Ch         ; stop program
    int 21h

    ret
game_over endp

;\--------------------------------------------------------------------------/
;|                           Generate Random Num.                           |
;/--------------------------------------------------------------------------\

get_rand proc   
   mov ah, 00h  ; get system time        
   int 1ah      ; cx:dx -> number of clock ticks since midnight      
   mov  ax, dx
   mov  dx, 0
   mov  cx, 5    
   div  cx      ; remainder of the division from 0 to 9

   ret   
get_rand endp

;\--------------------------------------------------------------------------/
;|                                  Delay                                   |
;/--------------------------------------------------------------------------\

delay proc 
    mov ax, 65530
loop1:
    dec ax
    cmp ax, 0
    jnz loop1
    
    mov ax, 65530
loop2:
    dec ax
    cmp ax, 0
    jnz loop2
    
    mov ax, 65530
loop3:
    dec ax
    cmp ax, 0
    jnz loop3
      
    ret
endp delay

;\--------------------------------------------------------------------------/
;|                                Draw Tile                                 |
;/--------------------------------------------------------------------------\

draw_tile proc
    ;dx,cx,al are set as the starting point(col,row) and color
    mov rst_col, cx
    mov end_col, cx
    mov end_row, dx
    add end_col, 4
    add end_row, 4
    mov ah, 0ch
    
    loop_tile:   
    int 10h       
    inc cx
    cmp cx, end_col   ; end of col
    jnz loop_tile 
    
    mov cx, rst_col   ; reset col
    inc dx
    cmp dx, end_row   ; end of row
    jnz loop_tile       
    
    ret    
draw_tile endp   

;\--------------------------------------------------------------------------/
;|                       Draw Piece - Line(Horizontal)                      |
;/--------------------------------------------------------------------------\

draw_line proc    
    mov al, curr_color
   
    mov cx, start_col   ; col = 153
    mov dx, start_row   ; row = 61
    call draw_tile
    
    mov cx, start_col 
    add cx, 4            ; col+4
    mov dx, start_row   
    call draw_tile
    
    mov cx, start_col 
    add cx, 8            ; col+8
    mov dx, start_row   
    call draw_tile
    
    mov cx, start_col 
    add cx, 12           ; col+12
    mov dx, start_row   
    call draw_tile
      
    mov curr_ang, 0
    ret
draw_line endp  

;\--------------------------------------------------------------------------/
;|                       Draw Piece - Line(Vertical)                        |
;/--------------------------------------------------------------------------\

draw_line_90 proc    
    mov al, curr_color 
   
    mov cx, start_col   ; col = 153
    mov dx, start_row   ; row = 61
    call draw_tile
    
    mov dx, start_row
    add dx, 4            ; row+4
    mov cx, start_col
    call draw_tile
    
    mov dx, start_row
    add dx, 8            ; row+8
    mov cx, start_col
    call draw_tile
    
    mov dx, start_row
    add dx, 12            ; row+12
    mov cx, start_col
    call draw_tile
    
    mov curr_ang, 90
    ret
draw_line_90 endp

;\--------------------------------------------------------------------------/
;|                          Draw Piece - Square                             |
;/--------------------------------------------------------------------------\

draw_square proc    
    mov al, curr_color   
       
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile

    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov dx, start_row
    call draw_tile 

    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile 
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    ret 
draw_square endp
    
;\--------------------------------------------------------------------------/
;|                             Draw Piece - T                               |
;/--------------------------------------------------------------------------\

draw_t proc    
    mov al, curr_color   
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile

    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov dx, start_row
    call draw_tile 

    mov bx, start_col
    add bx, 8           ; col+8
    mov cx, bx    
    mov dx, start_row
    call draw_tile 
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 0
    ret
draw_t endp

;\--------------------------------------------------------------------------/
;|                           Draw Piece - T(90)                             |
;/--------------------------------------------------------------------------\

draw_t_90 proc    
    mov al, curr_color   
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile

    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx    
    mov cx, start_col
    call draw_tile 

    mov bx, start_row
    add bx, 8           ; row+8
    mov dx, bx    
    mov cx, start_col
    call draw_tile 
    
    mov bx, start_col
    sub bx, 4           ; col-4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 90
    ret
draw_t_90 endp

;\--------------------------------------------------------------------------/
;|                          Draw Piece - T(180)                             |
;/--------------------------------------------------------------------------\

draw_t_180 proc    
    mov al, curr_color  
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile
    
    mov bx, start_col
    sub bx, 4           ; col-4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile 

    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 180
    ret
draw_t_180 endp

;\--------------------------------------------------------------------------/
;|                          Draw Piece - T(270)                             |
;/--------------------------------------------------------------------------\

draw_t_270 proc    
    mov al, curr_color  
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile

    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx    
    mov cx, start_col
    call draw_tile 

    mov bx, start_row
    add bx, 8           ; row+8
    mov dx, bx    
    mov cx, start_col
    call draw_tile 
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 270
    ret
draw_t_270 endp

;\--------------------------------------------------------------------------/
;|                             Draw Piece - L                               |
;/--------------------------------------------------------------------------\

draw_l proc
    mov al, curr_color   
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile     
         
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile 
   
    mov bx, start_row   
    add bx, 8           ; row+8
    mov dx, bx
    mov cx, start_col    
    call draw_tile
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 8           ; row+8
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 0
    ret
draw_l endp

;\--------------------------------------------------------------------------/
;|                           Draw Piece - L(90)                             |
;/--------------------------------------------------------------------------\

draw_l_90 proc
    mov al, curr_color 
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile     
         
    mov bx, start_col   
    add bx, 4           ; col+4
    mov cx, bx
    mov dx, start_row    
    call draw_tile 
   
    mov bx, start_col   
    add bx, 8           ; col+8
    mov cx, bx
    mov dx, start_row    
    call draw_tile 
       
    mov cx, start_col    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 90
    ret
draw_l_90 endp

;\--------------------------------------------------------------------------/
;|                          Draw Piece - L(180)                             |
;/--------------------------------------------------------------------------\

draw_l_180 proc
    mov al, curr_color   
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile     
    
    mov bx, start_col   
    add bx, 4           ; col+4
    mov cx, bx
    mov dx, start_row    
    call draw_tile
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 8           ; row+8
    mov dx, bx 
    call draw_tile
           
    mov curr_ang, 180
    ret
draw_l_180 endp  

;\--------------------------------------------------------------------------/
;|                          Draw Piece - L(270)                             |
;/--------------------------------------------------------------------------\

draw_l_270 proc
    mov al, curr_color  
    
    mov cx, start_col   ; col = 157
    mov dx, start_row   ; row = 61
    call draw_tile     
         
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile 
   
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov bx, start_col
    sub bx, 4           ; col-4
    mov cx, bx    
    call draw_tile
           
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov bx, start_col
    sub bx, 8           ; col-8
    mov cx, bx    
    call draw_tile
    
    mov curr_ang, 270
    ret
draw_l_270 endp

;\--------------------------------------------------------------------------/
;|                             Draw Piece - Z                               |
;/--------------------------------------------------------------------------\

draw_z proc
    mov al, curr_color   
    
    mov cx, start_col   ; col = 161
    mov dx, start_row   ; row = 61
    call draw_tile

    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov dx, start_row
    call draw_tile
    
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile
    
    mov bx, start_col
    sub bx, 4           ; col-4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 0
    ret  
draw_z endp

;\--------------------------------------------------------------------------/
;|                          Draw Piece - Z(90)                              |
;/--------------------------------------------------------------------------\    

draw_z_90 proc
    mov al, curr_color   
    
    mov cx, start_col   ; col = 161
    mov dx, start_row   ; row = 61
    call draw_tile
       
    mov bx, start_row   
    add bx, 4           ; row+4
    mov dx, bx
    mov cx, start_col    
    call draw_tile
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 4           ; row+4
    mov dx, bx 
    call draw_tile
    
    mov bx, start_col
    add bx, 4           ; col+4
    mov cx, bx    
    mov bx, start_row
    add bx, 8           ; row+8
    mov dx, bx 
    call draw_tile
    
    mov curr_ang, 90
    ret  
draw_z_90 endp

;\--------------------------------------------------------------------------/
;|                            Move Right                                    |
;/--------------------------------------------------------------------------\    

move_right proc         ; PRESS D
    mov curr_color, 0   ; set black color (for clearing)
    
    cmp curr_shape, 'r'
    jnz r1
          
        cmp curr_ang,0  ; horizontal line
        jnz vertical_line_r
        
        ; check right block 1 is empty
        mov bx, start_col
        add bx, 16
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh      ; get color of the block
        int 10h
        cmp al,0        ; move if al=0 (black)
        jnz end_d
        
        ; clear and draw new piece
        call draw_line          ; clear previous piece
        mov curr_color, 0Bh     ; set blue color
        add start_col,4         ; go right
        call draw_line          ; draw new piece
        jmp end_d
        
        vertical_line_r:
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ;check right block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx    
            mov ah,0Dh              ;get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ;check right block 3 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx            
            mov ah,0Dh              ; get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_d               
            
            ; check right block 4 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 12
            mov dx, bx 
            mov ah,0Dh              ;get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_line_90       ; clear previous piece
            mov curr_color, 0Bh     ; set blue color
            add start_col,4         ; go right
            call draw_line_90       ; draw new piece
            jmp end_d
         
    r1:
    cmp curr_shape, 't'
    jnz r2    
    
        cmp curr_ang,0
        jnz t90_r
        
        ; check right block 1 is empty
        mov bx, start_col
        add bx, 12
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh                  ; get color of the block
        int 10h
        cmp al,0                    ; move if al=0 (black)
        jnz end_d
        
        ; check right block 2 is empty
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx        
        mov ah,0Dh                  ; get color of the block
        int 10h 
        cmp al,0                    ; move if al=0 (black)
        jnz end_d
        
        ; clear and draw new piece
        call draw_t                 ; clear previous piece
        mov curr_color, 05h         ; set purple color
        add start_col,4             ; go right
        call draw_t                 ; draw new piece
        jmp end_d               
        
        t90_r:
            cmp curr_ang,90
            jnz t180_r
            
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row            
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
                     
            ; check right block 2 is empty         
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx            
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; check right block 3 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx  
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_t_90          ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_col,4         ; go right
            call draw_t_90          ; draw new piece
            jmp end_d
        
        t180_r:
            cmp curr_ang,180
            jnz t270_r
            
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row            
            mov ah,0Dh              ;get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
           ; check right block 2 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx            
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece 
            call draw_t_180         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_col,4         ; go right
            call draw_t_180         ; draw new piece
            jmp end_d
            
        t270_r:
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
                     
            ; check right block 2 is empty         
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; check right block 3 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_t_270         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_col,4         ; go right
            call draw_t_270         ; draw new piece
            jmp end_d
    
    r2:
    cmp curr_shape, 's'
    jnz r3
    
        ; check right block 1 is empty 
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
        
        ; check right block 2 is empty 
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx    
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
        
        ; clear and draw new piece    
        call draw_square        ; clear previous piece
        mov curr_color, 0Eh     ; set yellow color 
        add start_col,4         ; go right
        call draw_square        ; draw new piece
        jmp end_d        
        
    r3:
    cmp curr_shape, 'l'
    jnz r4
        
        cmp curr_ang,0
        jnz l90_r
        
        ; check right block 1 is empty
        mov bx, start_col
        add bx, 4
        mov cx, bx
        mov dx, start_row       
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
        
        ; check right block 2 is empty
        mov bx, start_col
        add bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx    
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
        
        ; check right block 3 is empty
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov bx, start_row
        add bx, 8
        mov dx, bx   
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_d  
        
        ; clear and draw new piece
        call draw_l             ; clear previous piece
        mov curr_color, 0Ch     ; set orange color
        add start_col,4         ; go right
        call draw_l             ; draw new piece
        jmp end_d
        
        l90_r:
            cmp curr_ang,90
            jnz l180_r  
            
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 12
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
           ; check right block 2 is empty 
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx  
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_l_90          ; clear previous piece
            mov curr_color, 0Ch     ; set orange color
            add start_col, 4        ; go right
            call draw_l_90          ; draw new piece
            jmp end_d
        
        l180_r:
            cmp curr_ang,180
            jnz l270_r
            
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; check right block 2 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; check right block 3 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx 
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d           
        
            ; clear and draw new piece
            call draw_l_180         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color
            add start_col, 4        ; go right
            call draw_l_180         ; draw new piece
            jmp end_d
            
        l270_r:
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; check right block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx                
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_l_270         ; first clear previous shape
            mov curr_color, 0Ch     ; color = orange
            add start_col,4         ; go right
            call draw_l_270         ; draw new piece
            jmp end_d 
     
    r4: ; case z             
        cmp curr_ang,0
        jnz z90_r
        
        ; check right block 1 is empty
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov dx, start_row     
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
            
        ; check right block 2 is empty    
        mov bx, start_col
        add bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx                
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_d
            
        ; clear and draw new piece
        call draw_z             ; clear previous piece
        mov curr_color, 0Ah     ; set green color 
        add start_col,4         ; go right
        call draw_z             ; draw new piece
        jmp end_d
        
        z90_r:
            ; check right block 1 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
                
           ; check right block 2 is empty     
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
             
            ; check right block 3 is empty 
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_d
            
            ; clear and draw new piece
            call draw_z_90          ; clear previous piece
            mov curr_color, 0Ah     ; set green color 
            add start_col,4         ; go right
            call draw_z_90          ; draw new piece
             
    end_d:
    ret    
move_right endp

;\--------------------------------------------------------------------------/
;|                              Move Left                                   |
;/--------------------------------------------------------------------------\    

move_left proc					; PRESS A
    mov curr_color, 0           ; set black color (for clearing)
    
    cmp curr_shape, 'r'
    jnz l1
    
        cmp curr_ang,0          ; horizontal line
        jnz vertical_line_l
        
        ; check left block is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_a
        
        ; clear and draw new piece
        call draw_line          ; clear previous piece
        mov curr_color, 0Bh     ; set blue color 
        sub start_col,4         ; go left
        call draw_line          ; draw new piece
        jmp end_a
        
        vertical_line_l:
            ; check left block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 2 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 3 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 4 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 12
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece
            call draw_line_90       ; clear previous piece
            mov curr_color, 0Bh     ; set blue color
            sub start_col,4         ; go left
            call draw_line_90       ; draw new piece
            jmp end_a
 
    l1:
    cmp curr_shape, 't'
    jnz l2    
    
        cmp curr_ang,0
        jnz t90_l
        
        ; check left block 1 is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_a
        
        ; check left block 2 is empty
        mov cx, start_col
        mov bx, start_row
        add bx, 4
        mov dx, bx
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_a
        
        ; clear and draw new piece
        call draw_t             ; clear previous piece
        mov curr_color, 05h     ; set purple color
        sub start_col,4         ; go left
        call draw_t             ; draw new piece
        jmp end_a
        
        t90_l:
            cmp curr_ang,90
            jnz t180_l
            
            ; check left block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
                     
            ; check left block 2 is empty         
            mov bx, start_col
            sub bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 3 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece
            call draw_t_90          ; clear previous piece
            mov curr_color, 05h     ; set purple color
            sub start_col,4         ; go left
            call draw_t_90          ; draw new piece
            jmp end_a
        
        t180_l:
            cmp curr_ang,180
            jnz t270_l
            
            ; check left block 1 is empty        
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 2 is empty        
            mov bx, start_col
            sub bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx              ; get color of the block
            mov ah,0Dh     
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a

            ; clear and draw new piece 
            call draw_t_180         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            sub start_col,4         ; go left
            call draw_t_180         ; draw new piece
            jmp end_a
        
        t270_l:
            ; check left block 1 is empty     
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
                     
            ; check left block 2 is empty              
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx  
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 3 is empty     
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece 
            call draw_t_270         ; clear previous piece 
            mov curr_color, 05h     ; set purple color  
            sub start_col,4         ; go left
            call draw_t_270         ; draw new piece
            jmp end_a
    
    l2:
    cmp curr_shape, 's'
    jnz l3
    
        ; check left block 1 is empty 
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov dx, start_row
        mov ah,0Dh                  ; get color of the block
        int 10h 
        cmp al,0                    ; move if al=0 (black)
        jnz end_a
        
        ; check left block 2 is empty 
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx    
        mov ah,0Dh                  ; get color of the block
        int 10h 
        cmp al,0                    ; move if al=0 (black)
        jnz end_a
        
        ; clear and draw new piece  
        call draw_square            ; clear previous piece
        mov curr_color, 0Eh         ; set yellow color  
        sub start_col,4             ; go left
        call draw_square            ; draw new piece
        jmp end_a
               
    l3:
    cmp curr_shape, 'l'
    jnz l4

        cmp curr_ang,0
        jnz l90_l
        
        ; check left  block 1 is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov dx, start_row       
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_a
        
        ; check left block 2 is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx    
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_a
        
        ; check left block 3 is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 8
        mov dx, bx   
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_a  
        
        ; clear and draw new piece
        call draw_l             ; clear previous piece
        mov curr_color, 0Ch     ; set orange color  
        sub start_col,4         ; go left
        call draw_l             ; draw new piece
        jmp end_a
        
        l90_l:
            cmp curr_ang,90
            jnz l180_l
            
            ; check left block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
           ; check left block 2 is empty 
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx  
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece
            call draw_l_90          ; clear previous piece
            mov curr_color, 0Ch     ; set orange color  
            sub start_col, 4        ; go left
            call draw_l_90          ; draw new piece
            jmp end_a
        
        l180_l:
            cmp curr_ang,180
            jnz l270_l
            
            ; check left block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 2 is empty
            mov cx, start_col
            mov bx, start_row
            add bx, 4
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 3 is empty
            mov cx, start_col
            mov bx, start_row
            add bx, 8
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a           
        
            ; clear and draw new piece 
            call draw_l_180         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color
            sub start_col, 4        ; go left
            call draw_l_180         ; draw new piece
            jmp end_a
        
        l270_l:
            ; check left block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; check left block 2 is empty
            mov bx, start_col
            sub bx, 12
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx                
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece
            call draw_l_270         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color
            sub start_col,4         ; go left
            call draw_l_270         ; draw new piece
            jmp end_a 
     
    l4: ; case z
           
        cmp curr_ang,0
        jnz z90_l
        
        ; check left block 1 is empty
        mov bx, start_col
        sub bx, 4
        mov cx, bx
        mov dx, start_row     
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_a
            
        ; check left block 2 is empty    
        mov bx, start_col
        sub bx, 8
        mov cx, bx
        mov bx, start_row
        add bx, 4
        mov dx, bx                
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz end_a
            
        ; clear and draw new piece
        call draw_z             ; clear previous piece
        mov curr_color, 0Ah     ; set green color
        sub start_col,4         ; go left
        call draw_z             ; draw new piece
        jmp end_a
        
        z90_l:
            ; check right block 1 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov dx, start_row
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
                
           ; check right block 2 is empty     
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
             
            ; check right block 3 is empty 
            mov cx, start_col
            mov bx, start_row
            add bx, 8
            mov dx, bx       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz end_a
            
            ; clear and draw new piece
            call draw_z_90          ; clear previous piece
            mov curr_color, 0Ah     ; set green color
            sub start_col,4         ; go left
            call draw_z_90          ; draw new piece
            jmp end_a
         
    end_a:
    ret        
move_left endp

;\--------------------------------------------------------------------------/
;|                             Move Down                                    |
;/--------------------------------------------------------------------------\    

move_down proc          		; PRESS S
    mov curr_color, 0   		; set black color (for clearing)
    
    cmp curr_shape, 'r'
    jnz d1
    
        cmp curr_ang,0  		; horizontal line
        jnz vertical_line
                     
            ; clear and draw new piece
            call draw_line          ; clear previous piece
            mov curr_color, 0Bh     ; set blue color  
            add start_row,4         ; go down
            call draw_line          ; draw new piece
            jmp end_s
            
        vertical_line:
            ; clear and draw new piece
            call draw_line_90       ; clear previous piece
            mov curr_color, 0Bh     ; set blue color  
            add start_row,4         ; go down
            call draw_line_90       ; draw new piece
            jmp end_s
          
    d1:
    cmp curr_shape, 't'
    jnz d2    
    
        cmp curr_ang,0
        jnz t90
        
            ; clear and draw new piece
            call draw_t             ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_row,4         ; go down
            call draw_t             ; draw new piece
            jmp end_s
        
        t90:
        cmp curr_ang,90
        jnz t180  
                                     
            ; clear and draw new piece
            call draw_t_90          ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_row,4         ; go down
            call draw_t_90          ; draw new piece
            jmp end_s
        
        t180:
        cmp curr_ang,180
        jnz t270
                               
            ; clear and draw new piece
            call draw_t_180         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_row,4         ; go down
            call draw_t_180         ; draw new piece
            jmp end_s
        
        t270:                     
            ; clear and draw new piece
            call draw_t_270         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            add start_row,4         ; go down
            call draw_t_270         ; draw new piece
            jmp end_s              
               
    d2:
    cmp curr_shape, 's'
    jnz d3
               
        ; clear and draw new piece  
        call draw_square        ; clear previous piece
        mov curr_color, 0Eh     ; set yellow color  
        add start_row,4         ; go down
        call draw_square        ; draw new piece
        jmp end_s
                
    d3:
    cmp curr_shape, 'l'
    jnz d4

        cmp curr_ang,0
        jnz l90 
                      
            ; clear and draw new piece
            call draw_l             ; clear previous piece
            mov curr_color, 0Ch     ; set orange color  
            add start_row,4         ; go down
            call draw_l             ; draw new piece
            jmp end_s
        
        l90:
        cmp curr_ang,90
        jnz l180 
                                       
            ; clear and draw new piece
            call draw_l_90          ; clear previous piece
            mov curr_color, 0Ch     ; set orange color  
            add start_row,4         ; go down
            call draw_l_90          ; draw new piece
            jmp end_s
        
        l180:
        cmp curr_ang,180
        jnz l270   
                                     
            ; clear and draw new piece
            call draw_l_180         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color  
            add start_row,4         ; go down
            call draw_l_180         ; draw new piece
            jmp end_s
        
        l270:                           
            ; clear and draw new piece
            call draw_l_270         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color  
            add start_row,4         ; go down
            call draw_l_270         ; draw new piece
            jmp end_s
    
    d4: ; case z       
        
        cmp curr_ang,0
        jnz z90
            
            ; clear and draw new piece
            call draw_z             ; clear previous piece
            mov curr_color, 0Ah     ; set green color 
            add start_row,4         ; go down
            call draw_z             ; draw new piece
            jmp end_s
        
        z90:                         
            ; clear and draw new piece
            call draw_z_90          ; clear previous piece
            mov curr_color, 0Ah     ; set green color 
            add start_row,4         ; go down
            call draw_z_90          ; draw new piece
            jmp end_s
              
    end_s:    
    ret    
move_down endp

;\--------------------------------------------------------------------------/
;|                            Move Down Fast                                |
;/--------------------------------------------------------------------------\    

fast_down proc		; PRESS F        
    check_down_loop:
        call check_down
        cmp down_blockd, 1
        jnz end_f 
        call move_down
        jmp check_down_loop
    
    end_f:        
    ret    
fast_down endp    
 
;\--------------------------------------------------------------------------/
;|                              Check Down                                  |
;/--------------------------------------------------------------------------\    
 
check_down proc

    cmp curr_shape, 'r'
    jnz check_down1
    
        ; horizontal line
        cmp curr_ang,0  
        jnz vertical_line_cd
        
           ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block            
            
            ; check bottom block 2 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block  
            
            ; check bottom block 3 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov bx, start_col
            add bx, 8
            mov cx, bx     
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block  
            
            ; check bottom block 4 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov bx, start_col
            add bx, 12
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block  
            jmp check_down_end 
        
       vertical_line_cd:
            ; check bottom block is empty
            mov bx, start_row
            add bx, 16
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block 
            jmp check_down_end 
                
    check_down1:
    cmp curr_shape, 't'
    jnz check_down2
    
        cmp curr_ang,0
        jnz t90_cd
            
            ; check bottom block 1 is empty
            mov cx, start_col
            mov bx, start_row
            add bx, 4
            mov dx, bx        
            mov ah,0Dh               ; get color of the block
            int 10h 
            cmp al,0                 ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx        
            mov ah,0Dh               ; get color of the block
            int 10h 
            cmp al,0                 ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 3 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block    
            jmp check_down_end 
                                    
        t90_cd:
        cmp curr_ang,90
        jnz t180_cd
        
             ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 12
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov bx, start_col            
            sub bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block    
            jmp check_down_end 
            
        t180_cd:
        cmp curr_ang,180
        jnz t270_cd
            
            ; check bottom block 1 is empty
            mov cx, start_col
            mov bx, start_row
            add bx, 8
            mov dx, bx        
            mov ah,0Dh               ; get color of the block
            int 10h 
            cmp al,0                 ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx        
            mov ah,0Dh               ; get color of the block
            int 10h 
            cmp al,0                 ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 3 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end  
                           
        t270_cd:        
            ; check bottom block 1 is empty 
            mov bx, start_row
            add bx, 12
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov bx, start_col            
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end  
   
    check_down2:
    cmp curr_shape, 's'
    jnz check_down3
        
        ; check bottom block 1 is empty 
        mov bx, start_row
        add bx, 8
        mov dx, bx
        mov cx, start_col
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz check_down_end_block
        
        ; check bottom block 2 is empty 
        mov bx, start_col
        add bx, 4
        mov cx, bx
        mov bx, start_row
        add bx, 8
        mov dx, bx
        mov ah,0Dh              ; get color of the block
        int 10h 
        cmp al,0                ; move if al=0 (black)
        jnz check_down_end_block
        jmp check_down_end
        
    check_down3:
    cmp curr_shape, 'l'
    jnz check_down4
    
        cmp curr_ang,0
        jnz l90_cd
        
            ; check bottom block 1 is empty
            mov bx, start_row 
            add bx, 12
            mov dx, bx
            mov cx, start_col      
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 12
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end
                            
        l90_cd:
        cmp curr_ang,90
        jnz l180_cd
        
            ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 3 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx   
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end
                                 
        l180_cd:
        cmp curr_ang,180
        jnz l270_cd
            
            ; check bottom block 1 is empty
            mov bx, start_row 
            add bx, 4
            mov dx, bx
            mov cx, start_col      
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 12
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block  
            jmp check_down_end 
            
        l270_cd:
            ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 2 is empty
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx    
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            
            ; check bottom block 3 is empty
            mov bx, start_col
            sub bx, 8
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx   
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end        
       
    check_down4:  ;'z'
    cmp curr_ang,0
    jnz z90_cd   
        
            ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
                
           ; check bottom block 2 is empty     
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 4
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
             
            ; check bottom block 3 is empty 
            mov bx, start_col
            sub bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 8
            mov dx, bx       
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end  
                
        z90_cd:
            ; check bottom block 1 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
                
           ; check bottom block 2 is empty     
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov bx, start_row
            add bx, 12
            mov dx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h 
            cmp al,0                ; move if al=0 (black)
            jnz check_down_end_block
            jmp check_down_end  
        
    check_down_end_block:
        mov down_blockd, 0  
    
    check_down_end:         
    ret       
check_down endp               

;\--------------------------------------------------------------------------/
;|                                Rotate                                    |
;/--------------------------------------------------------------------------\    

rotate proc             ; PRESS W
    mov curr_color, 0   ; set black color (for clearing)
    
    cmp curr_shape, 's'
    jnz ro1             ; rotated square is itself 
    jmp end_w
       
    ro1:
    cmp curr_shape, 't'
    jnz ro2
    
        cmp curr_ang, 0
        jnz ang_t2
           
        ; check index 2 is empty
        mov bx, start_row
        add bx, 4
        mov dx, bx
        mov cx, start_col        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
            
        ; check index 3 is empty
        mov bx, start_row
        add bx, 8
        mov dx, bx
        mov cx, start_col        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
                 
        ; check index 4 is empty
        mov bx, start_row
        add bx, 4
        mov dx, bx
        mov cx, start_row
        mov bx, start_col
        sub bx, 4
        mov cx, bx        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
        
        ; clear and draw new piece    
        call draw_t             ; clear previous piece
        mov curr_color, 05h     ; set purple color
        call draw_t_90          ; rotate and draw new piece
        jmp end_w
                  
        ang_t2:
            cmp curr_ang, 90
            jnz ang_t3
            
            ; check index 3 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w            
            
            ; clear and draw new piece
            call draw_t_90          ; clear previous piece
            mov curr_color, 05h     ; set purple color
            call draw_t_180         ; rotate and draw new piece
            jmp end_w
                 
        ang_t3:
            cmp curr_ang, 180
            jnz ang_t4          
            
            ; check index 3 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h                 
            cmp al,0                ; move if al=0 (black)
            jnz end_w  
            
            ; clear and draw new piece
            call draw_t_180         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            call draw_t_270         ; rotate and draw new piece
            jmp end_w
         
        ang_t4:
            ; check index 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row        
            mov ah,0Dh              ; get color of the block
            int 10h                 
            cmp al,0                ; move if al=0 (black)
            jnz end_w
                        
            ; check index 3 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov dx, start_row        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
           ; clear and draw new piece        
            call draw_t_270         ; clear previous piece
            mov curr_color, 05h     ; set purple color
            call draw_t             ; rotate and draw new piece
            jmp end_w
            
    ro2:
    cmp curr_shape,'l'
    jnz ro3
    
        cmp curr_ang, 0
        jnz ang_l2
        
        ; check index 2 is empty
        mov bx, start_col
        add bx, 4
        mov cx, bx
        mov dx, start_row        
        mov ah,0Dh              ; get color of the block
        int 10h                 
        cmp al,0                ; move if al=0 (black)
        jnz end_w
                        
        ; check index 1 is empty
        mov bx, start_col
        add bx, 8
        mov cx, bx
        mov dx, start_row        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
                   
        ; clear and draw new piece
        call draw_l             ; clear previous piece
        mov curr_color, 0Ch     ; set orange color 
        call draw_l_90          ; rotate and draw new piece
        jmp end_w         
         
        ang_l2:
            cmp curr_ang, 90
            jnz ang_l3
            
            ; check index 2 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w 
            
            ; check index 1 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
                        
            ; clear and draw new piece 
            call draw_l_90          ; clear previous piece
            mov curr_color, 0Ch     ; set orange color     
            call draw_l_180         ; rotate and draw new piece
            jmp end_w
                   
        ang_l3:
            cmp curr_ang, 180
            jnz ang_l4
            
            ; check index 3 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
            ; check index 2 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            sub bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w            
            
            ; check index 1 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            sub bx, 8
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
                        
            ; clear and draw new piece
            call draw_l_180         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color     
            call draw_l_270         ; rotate and draw new piece
            jmp end_w
         
        ang_l4:           
            ; check index 3 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_col        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w    
        
            ; check index 4 is empty
            mov bx, start_row
            add bx, 8
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
        
           ; clear and draw new piece          
            call draw_l_270         ; clear previous piece
            mov curr_color, 0Ch     ; set orange color
            call draw_l             ; rotate and draw new piece
            jmp end_w    
    
    ro3:
    cmp curr_shape,'z'
    jnz ro4
    
        cmp curr_ang, 0
        jnz ang_z2
                
        ; check index 3 is empty
        mov bx, start_row
        add bx, 4
        mov dx, bx
        mov cx, start_row
        mov bx, start_col
        add bx, 4
        mov cx, bx        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
            
        ; check index 4 is empty
        mov bx, start_row
        add bx, 8
        mov dx, bx
        mov cx, start_row
        mov bx, start_col
        add bx, 4
        mov cx, bx        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w                     
        
        ; clear and draw new piece 
        call draw_z                 ; clear previous piece
        mov curr_color, 0Ah         ; set green color     
        call draw_z_90              ; rotate and draw new piece
        jmp end_w
                  
        ang_z2:     ; case 90
            ; check index 2 is empty
            mov dx, start_row
            mov bx, start_col
            add bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
            ; check index 3 is empty
            mov bx, start_row
            add bx, 4
            mov dx, bx
            mov cx, start_row
            mov bx, start_col
            sub bx, 4
            mov cx, bx        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w            
            
            ; clear and draw new piece
            call draw_z_90          ; clear previous piece
            mov curr_color, 0Ah     ; set green color  
            call draw_z             ; rotate and draw new piece
            jmp end_w
        
    ro4:        ;case r       
        cmp curr_ang, 0         ; horizontal line
        jnz ang_r2
        
        ; check index 2 is empty
        mov bx, start_row
        add bx, 4
        mov dx, bx
        mov cx, start_col               
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
        
        ; check index 3 is empty
        mov bx, start_row
        add bx, 8
        mov dx, bx
        mov cx, start_col        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
        
        ; check index 4 is empty
        mov bx, start_row
        add bx, 12
        mov dx, bx
        mov cx, start_col        
        mov ah,0Dh              ; get color of the block
        int 10h             
        cmp al,0                ; move if al=0 (black)
        jnz end_w
              
        ; clear and draw new piece
        call draw_line          ; clear previous piece
        mov curr_color, 0Bh     ; set blue color 
        call draw_line_90       ; rotate and draw new piece
        jmp end_w
                 
        ang_r2:              ; case 90           
            ; check index 2 is empty
            mov bx, start_col
            add bx, 4
            mov cx, bx
            mov dx, start_row        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
            ; check index 3 is empty
            mov bx, start_col
            add bx, 8
            mov cx, bx
            mov dx, start_row        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
            ; check index 4 is empty
            mov bx, start_col
            add bx, 12
            mov cx, bx
            mov dx, start_row        
            mov ah,0Dh              ; get color of the block
            int 10h             
            cmp al,0                ; move if al=0 (black)
            jnz end_w
            
            ; clear and draw new piece
            call draw_line_90       ; clear previous piece
            mov curr_color, 0Bh     ; set blue color 
            call draw_line          ; rotate and draw new piece
        
    end_w:
    ret    
rotate endp

;\--------------------------------------------------------------------------/
;|                        Delete & Shift Full Rows                          |
;/--------------------------------------------------------------------------\    

check_full proc

    mov full_rows_num, 0 ; reset
            
    ; 1. check shape, 2. check angle, 3. check rows related to the shape
    cmp curr_shape, 'r'
    jnz maybe_l
    
        cmp curr_ang, 0
        jnz r_ang_90
        
        ; check row 1       
        mov cx, srch_str_col        ;141
        mov dx, start_row
        check_row_r:
            mov ah, 0Dh             ; get color of the block
            int 10h
            cmp al, 0
            je end_check            ; row is not full
            add cx, 4               ; check next col         
            cmp cx, srch_end_col    ; end of border
            jle check_row_r
            inc full_rows_num
            push start_row 
            jmp end_check        
        
        r_ang_90:
                        
        ; check row 4
        check_row_r90_4:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 12
            
            check_row_r90_4_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_r90_3      ; row is not full
                add cx, 4               ; check next col            
                cmp cx, srch_end_col    ; end of border
                jle check_row_r90_4_
                inc full_rows_num
                push dx                 ; push start_row+12                   
                
        ; check row 3
        check_row_r90_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_r90_3_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_r90_2      ; row is not full
                add cx, 4               ; check next col       
                cmp cx, srch_end_col    ; end of border
                jle check_row_r90_3_
                inc full_rows_num
                push dx                 ; push start_row+8
                                        
        ; check row 2
        check_row_r90_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_r90_2_:                   
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_r90_1      ; row is not full
                add cx, 4               ; check next col        
                cmp cx, srch_end_col    ; end of borderr
                jle check_row_r90_2_
                inc full_rows_num
                push dx                 ; push start_row+4     
        
        ; check row 1
        check_row_r90_1:
        mov cx, srch_str_col
        mov dx, start_row
            
            check_row_r90_1_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check next col         
                cmp cx, srch_end_col    ; end of border
                jle check_row_r90_1_
                inc full_rows_num
                push start_row
                jmp end_check            
                            
    maybe_l:
    cmp curr_shape, 'l'
    jnz maybe_t
    
        cmp curr_ang, 0
        jnz l_ang_90
        
        ; check row 3
        check_row_l_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_l_3_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_2        ; row is not full
                add cx, 4               ; check block of the next row          
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_3_
                inc full_rows_num
                push dx                 ; push start_row+8                
                
        ; check row 2
        check_row_l_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_l_2_:           
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_1        ; row is not full
                add cx, 4               ; check block of the next row          
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_2_
                inc full_rows_num
                push dx                 ; push start_row+4  
                                                
        ; check row 1
        check_row_l_1:
        mov cx, srch_str_col
        mov dx, start_row
        
            check_row_l_1_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check next col          
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_1_
                inc full_rows_num
                push start_row
                jmp end_check            
                       
        l_ang_90:
        cmp curr_ang, 90
        jnz l_ang_180

        ; check row 2
        check_row_l_90_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_l_90_2_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_90_1     ; row is not full
                add cx, 4               ; check block of the next row          
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_90_2_    
                inc full_rows_num
                push dx                 ; push start_row+4 
                                        
        ; check row 1
        check_row_l_90_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_l_90_1_:
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check block of the next row       
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_90_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                    
        l_ang_180:
        cmp curr_ang, 180
        jnz l_ang_270

        ; check row 3
        check_row_l_180_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_l_180_3_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_180_2    ; row is not full
                add cx, 4               ; check block of the next row          
                cmp cx, srch_end_col    ; end of borderr
                jle check_row_l_180_3_
                inc full_rows_num
                push dx                 ; push start_row+8                 
                
        ; check row 2
        check_row_l_180_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_l_180_2_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_180_1    ; row is not full
                add cx, 4               ; check block of the next row      
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_180_2_
                inc full_rows_num
                push dx                 ; push start_row+4 
                                
        ; check row 1
        check_row_l_180_1:
        mov cx, srch_str_col
        mov dx, start_row
        
        check_row_l_180_1_:            
            mov ah, 0Dh             ; get color of the block
            int 10h
            cmp al, 0
            je end_check            ; row is not full
            add cx, 4               ; check block of the next row        
            cmp cx, srch_end_col    ; end of border
            jle check_row_l_180_1_
            inc full_rows_num
            push start_row 
            jmp end_check
               
        l_ang_270:
                
        ; check row 2
        check_row_l_270_2:
        mov cx, srch_str_col
        mov dx, start_row
        add dx, 4
            
            check_row_l_270_2_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_l_270_1    ; row is not full
                add cx, 4               ; check block of the next row          
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_270_2_
                inc full_rows_num
                push dx                 ; push start_row+4                
                
        ; check row 1
        check_row_l_270_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_l_270_1_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check block of the next row        
                cmp cx, srch_end_col    ; end of border
                jle check_row_l_270_1_
                inc full_rows_num
                push start_row
                jmp end_check 
                                
    maybe_t:
    cmp curr_shape, 't'
    jnz maybe_z
    
        cmp curr_ang, 0
        jnz t_ang_90

        ; check row 2
        check_row_t_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_t_2_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_1        ; row is not full
                add cx, 4               ; check block of the next row         
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_2_
                inc full_rows_num
                push dx                 ; push start_row+4                
                
        ; check row 1
        check_row_t_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_t_1_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check block of the next row           
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                      
        t_ang_90:
        jnz t_ang_180

        ; check row 3
        check_row_t_90_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_t_90_3_:
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_90_2     ; row is not full
                add cx, 4               ; check block of the next row     
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_90_3_
                inc full_rows_num
                push dx                

        ; check row 2
        check_row_t_90_2:  
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
             
            check_row_t_90_2_:           
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_90_1     ; row is not full
                add cx, 4               ; check block of the next row  
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_90_2_
                inc full_rows_num
                push dx
                                
        ; check row 1
        check_row_t_90_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_t_90_1_:           
                mov ah, 0Dh                 ; get color of the block
                int 10h
                cmp al, 0
                je end_check                ; row is not full
                add cx, 4                   ; check block of the next row   
                cmp cx, srch_end_col        ; end of border
                jle check_row_t_90_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                
        t_ang_180:
        cmp curr_ang, 180
        jnz t_ang_270
        
        check_row_t_180_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_t_180_2_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_180_1    ; row is not full
                add cx, 4               ; check block of the next row         
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_180_2_
                inc full_rows_num
                push dx                 ; push start_row+4                
                      
        check_row_t_180_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_t_180_1_:            
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check block of the next row           
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_180_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                       
        t_ang_270: 
                       
        check_row_t_270_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_t_270_3_:
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_270_2    ; row is not full
                add cx, 4               ; check block of the next row     
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_270_3_
                inc full_rows_num
                push dx                

        check_row_t_270_2:  
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
             
            check_row_t_270_2_:           
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je check_row_t_270_1    ; row is not full
                add cx, 4               ; check block of the next row  
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_270_2_
                inc full_rows_num
                push dx
                                
        check_row_t_270_1:
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_t_270_1_:           
                mov ah, 0Dh             ; get color of the block
                int 10h
                cmp al, 0
                je end_check            ; row is not full
                add cx, 4               ; check block of the next row   
                cmp cx, srch_end_col    ; end of border
                jle check_row_t_270_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                    
    maybe_z:
    cmp curr_shape, 'z'
    jnz is_s
    
        cmp curr_ang, 0
        jnz z_ang_90
        
        check_row_z_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_z_2_:                
                mov ah, 0Dh                 ; get color of the block
                int 10h 
                cmp al, 0
                je check_row_z_1            ; row is not full
                add cx, 4                   ; check block of the next row    
                cmp cx, srch_end_col        ; end of border
                jle check_row_z_2_
                inc full_rows_num
                push dx                        
                
        check_row_z_1: 
            mov cx, srch_str_col
            mov dx, start_row
            
            check_row_z_1_:                
                mov ah, 0Dh                 ; get color of the block
                int 10h
                cmp al, 0
                je end_check           		; row is not full
                add cx, 4                   ; check block of the next row        
                cmp cx, srch_end_col        ; end of border
                jle check_row_z_1_
                inc full_rows_num
                push start_row 
                jmp end_check
                        
        z_ang_90:
                
        check_row_z_90_3:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 8
            
            check_row_z_90_3_:                            
                mov ah,0Dh                  ; get color of the block
                int 10h
                cmp al,0
                je check_row_z_90_2         ; row is not full
                add cx, 4                   ; check block of the next row  
                cmp cx, srch_end_col        ; end of border
                jle check_row_z_90_3_
                inc full_rows_num
                push dx
                         
        check_row_z_90_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_z_90_2_:                            
                mov ah,0Dh                  ; get color of the block
                int 10h
                cmp al,0
                je check_row_z_90_1         ; row is not full
                add cx, 4                   ; check block of the next row  
                cmp cx, srch_end_col        ; end of border
                jle check_row_z_90_2_
                inc full_rows_num
                push dx        
                        
        check_row_z_90_1: 
            mov cx, srch_str_col
            mov dx, start_row 
            
            check_row_z_90_1_:            
                mov ah, 0Dh                 ; get color of the block
                int 10h
                cmp al, 0
                je end_check         		; row is not full
                add cx, 4                   ; check block of the next row  
                cmp cx, srch_end_col        ; end of border
                jle check_row_z_90_1_
                inc full_rows_num
                push start_row 
                jmp end_check
            
    is_s:
        check_row_s_2:
            mov cx, srch_str_col
            mov dx, start_row
            add dx, 4
            
            check_row_s_2_:            
                mov ah, 0Dh                 ; get color of the block
                int 10h
                cmp al, 0
                je check_row_s_1            ; row is not full
                add cx, 4                   ; check block of the next row        
                cmp cx, srch_end_col        ; end of border
                jle check_row_s_2_
                inc full_rows_num
                push dx       
         
        check_row_s_1:
        mov cx, srch_str_col
        mov dx, start_row
        check_row_s_1_:           
            mov ah, 0Dh                 ; get color of the block
            int 10h
            cmp al, 0
            je end_check            	; row is not full
            add cx, 4                   ; check block of the next row  
            cmp cx, srch_end_col        ; end of border
            jle check_row_s_1_
            inc full_rows_num
            push start_row 
            jmp end_check
                                     
    end_check:
        mov bx,full_rows_num
        cmp bx,2
        jge x2
        
        plus:
            mov ax, bx
            mul ten 
            add score, ax ; update score
            call show_score
            jmp base_check
        
        x2:
            mov ax, 2
            mul bx
            mov bx, ax
            jmp plus
                
    ; shift rows down
    base_check:
        cmp full_rows_num,0
        je done_shift
         
        pop curr_row    ; row that shoud be shifted
    
    next_row:
        mov bx, srch_str_col        
     
    continue_color:
        ; get color of the above row
        mov dx, curr_row    
        sub dx, 4       ; upper row    
        mov cx, bx      ; srch_str_col
        mov ah,0Dh      ; get color of the block
        int 10h         ; now color (al) is set with upper block
        
        ; color bottom row
        mov dx, curr_row
        call draw_tile
        
        ;go next col
        add bx, 4
        cmp bx, srch_end_col   
        jle continue_color
        
        ;go next row
        sub curr_row, 4
        mov bx, curr_row
        cmp bx, brd_ur
        jnz next_row 
              
        dec full_rows_num        
        jmp base_check
    
    done_shift:
    ret
check_full endp
                              