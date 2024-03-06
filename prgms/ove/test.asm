org #0000
;copy fibmain to ram
;src 12-13
;dst 0-1

;set high byte of dest addr
ldi %5 @7
mov @6 @5
ldi %1 @7
mov @5 @6

;set high byte of src addr
ldi %13 @7
ldi %2 @6

;copy until #7f
;#7f is 0b01111111
;generate #7f to compare against
ldi %4 @7
ldi #3f @2
mov @6 @1
or
mov @3 @2

label copyLoop
ldi %14 @7 ;get next src byte
mov @6 @1
sub ;check if #7f
jez copyDone

ldi %2 @7 ;copy to dest
mov @1 @6

;inc both addr
mov @2 @4
    ldi %1 @2
    ldi %12 @7
    mov @6 @1
    add
    ;jmp copyDone ac
    mov @3 @6
    ldi %0 @7
    mov @6 @1
    add
    ;jmp copyDone ac
    mov @3 @6
mov @4 @2

jmp copyLoop


label copyDone
;loop done
;copy done

;run fibmain
ldi %3 @7
mov @5 @6

ldi %0
jmp

org #0200
org #8000 soft
label fibmain
    ldi %1 @1
    ldi %0 @2

    ldi %0 @7
    ldi %48 @6
    ldi %5 @7
    mov @6 @5
    ldi %1 @7
    mov @5 @6

label fib
    add
    mov @2 @1
    mov @3 @2
    jmp done ac
    ;put fib to ram
        mov @1 @4 ;save fib values
        mov @2 @5
        ldi %2 @7 ;set up ram access
        mov @3 @6 ;write to ram

        ldi %0 @7 ;set up addr inc
        ldi %1 @2 ;set up inc
        mov @6 @1
        add ;inc
        mov @3 @6 ;write ram addr
        ;load fib values
        mov @4 @1
        mov @5 @2
    jmp fib
label done
    ;set up long jump
    ldi %3 @7 ;switches r7 to access high byte of jump addr
    ldi %1 @6 ;set page to 1
    jmp finishDemo  ;jump to next page

db #7f ;stop byte

org #0100
label finishDemo
    jmp finishDemo

db #7f 

label helloMessage
db "hello there" %0
