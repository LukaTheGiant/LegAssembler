require "erb"

def printLeg(bin, max: -1)
  x = bin[0..max]
  x.each_slice(4) do |a|
    puts "#{a[0]} #{a[1]} #{a[2]} #{a[3]} "
  end
end

fileName = "datastacktest"

fileName = ARGV[0] if ARGV.length>0

require_relative "obj/tokenizer"
require_relative "obj/leg"
require_relative 'obj/overture'
require_relative "obj/number"

t = Tokenizer.new
t.tokenizeFile("./prgms/#{fileName}.asm")

# m = LEG
m = Overture

m.assemble(t)
print '.'
m.link(t)
print '.'

bin = m.compile(t)
# printLeg bin,max:(10*4)-1
# p bin[0..100]
# bin[256..270].each do |x|
#   puts x.to_s()
# end
f = File.open("./bin/#{fileName}.#{m::ArchName}.bin", "wb")
f.write bin.pack(m::PackCharm)

f.close

puts ".\ndone"