org #0000

label main 
    ldi %0 @0
    ldi %1 @1
    ldi %0 @6

label fib
    add @0 @1 @2
    jc done
    mov @1 @0
    mov @2 @1
    wmem @6 @2
    add %1 @6 @6
    jmp fib

    ;fib is done

label done
    jmp done
