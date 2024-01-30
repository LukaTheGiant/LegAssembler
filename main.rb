require 'erb'


def printLeg(bin,max:-1)
    x = bin[0..max]
    x.each_slice(4) do |a|
        puts "#{a[0]} #{a[1]} #{a[2]} #{a[3]} "
    end
end    

fileName='fib'

require_relative "obj/tokenizer"
require_relative "obj/leg"
require_relative "obj/number"

t = Tokenizer.new
t.tokenizeFile("./prgms/#{fileName}.asm")

LEG.assemble(t)

LEG.link(t)

bin = LEG.compile(t)

f = File.open("./bin/#{fileName}.bin",'wb')
f.write bin.pack("S*")
