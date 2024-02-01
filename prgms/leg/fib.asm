
label main
    ldi %1 @1
    ldi %0 @2

label fib
    add @1 @2 @3
    jc done
    mov @2 @1
    mov @3 @2
    mov @3 @0
    call SCR_UI8_print

    jmp fib

    ;fib is done

label done
    jmp done

include lib/screen
