label main
    ldi %1 @1
    ldi %0 @2

label fib
    add
    mov @2 @1
    mov @3 @2
    jmp done ac
    ;put fib to ram
        ldi %1 @7 ;set r7 bank to ram access
        mov @3 @6 ;save fib to ram
        ;save values
        mov @1 @4
        mov @2 @5
        ;inc ram addr
        ldi %2 @7
        mov @6 @1
        ldi %1 @2
        add
        mov @3 @6

        ;load values
        mov @4 @1
        mov @5 @2
    jmp fib

label done
    ;set up long jump
    ldi %4 @7 ;switches r7 to access high byte of jump addr
    ldi %1 @6 ;set page to 1
    jmp help  ;jump to next page

org #0100
label finishDemo
    ldi %16 @1
    mov @0 @2
    

label demoLoop
    