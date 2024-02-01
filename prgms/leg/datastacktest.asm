


label main
    call DataStack_init

label makeOverflow
    add @0 %1 @0
    call DS.push
    jmp makeOverflow

include leg/lib/memstack