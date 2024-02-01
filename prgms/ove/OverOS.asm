org #0000

    ;entry point to os

    ;generate high bits
    ldi ^00100000 @1
    ldi %1 @2

    shl
    mov @3 @4
    mov @3 @1
    shl
    mov @3 @5

    
    ;check if os has ever been initialized
    ldi %5 @7
    ldi ^00111111 @1
    mov @5 @2
    or
    mov @3 @1
    mov @4 @2
    or
    mov @3 @6

    ldi %7 @7
    ldi ^00101010 @2
    mov @6 @1
    sub
    jez initDone

    ;if not, initialize os
    


    ;run os
label initDone

