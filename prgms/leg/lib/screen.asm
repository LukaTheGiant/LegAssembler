include lib/memstack

;This file is for screen instructions
<% fileRequire 'screen' %>

label SCR_UI8_print
    push @0
    push @1
    push @6
    ldi %0 @6
    
label SCR_UI8_print_DIGLOOP
    mod @0 %10 @1 ; extract bottom digit
    push @1 ;push 
    add @6 %1 @6 ;inc dig cnt
    div @0 %10 @0 ;strip bottom digit
    jne @0 %0 SCR_UI8_print_DIGLOOP ;any digits left?

    ;get screen ptr
    rmem %<%=SCR::PTR%> @1 ;read scr::ptr


label SCR_UI8_print_PRINTLOOP
    pop @0
    add %<%= '0'.ord %> @0 @0
    wcon @1 @0
    add %1 @1 @1
    sub @6 %1 @6
    jne %0 @6 SCR_UI8_print_PRINTLOOP
    
label SCR_UI8_print_PRINTLOOPDONE
    add @1 %1 @1  ;inc screen ptr to give space
    wmem %<%SCR::PTR%> @1 ;update scr::ptr in memory

    pop @6
    pop @1
    pop @0
    ret