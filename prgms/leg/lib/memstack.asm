;Create a constant
<% fileRequire 'memstack' %>

label DataStack_init
    ;stack takes up the last section of ram
    ;stack ptr is at #ff
    ;stack starts at #fe 
    wmem #ff #fe ;write initial ptr
    ret

label DS.push
    ;push r0 onto stack
    ;use hardware stack to save values overwritten
    push @6

    rmem #ff @6 ;read stack pointer
    jeq %<%= 0xfe-DataStack::MaxSize %> @6 DS.overflow ;check size

    ;within bounds

    wmem @6 @0;save value
    sub @6 %1 @6;dec sp
    
    wmem #ff @6;save sp

    ;ret
    pop @6
    ret

label DS.pop
    ;pop into r0

    ;save overwritten values
    push @6

    rmem #ff @6;read sp
    jeq #fe @6 DS.underflow ;check underflow
    
    add @6 %1 @6;inc sp
    rmem @6 @0;read value

    wmem #ff @6;save sp

    pop @6
    ret

label DS.overflow
    ldi %1 @6
    jmp DS.error

label DS.underflow
    ldi %-1 @6

label DS.error
    <% "ERROR".chars.each_with_index do |char,i| %>
    wcon %<%= i %> %<%= char.ord %>
    <% end %>

    div @6 %0 @5
