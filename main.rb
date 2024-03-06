require "erb"
require 'optparse'
require 'fileutils'
require_relative "obj/tokenizer"
require_relative "obj/number"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb fileName [options]"

  opts.on("--arch [ARCH]", String)
  opts.on('-o', '--out [OutputFile]', String)
  
end.parse!(into:options)

options[:arch] = 'ove' if options[:arch].nil?

case options[:arch]
when "ove"
  require_relative 'obj/overture'
  m = Overture
when "oven"
  require_relative 'obj/overtureNext'
  m = OvertureNext
when "leg"
  require_relative 'obj/leg'
  m = LEG
else
 raise "Arch #{options[:arch]} is not supported"
end

filePath = ARGV[0]
filePath=filePath.gsub("\\","/") #patch to help with windows paths
# pp filePath
fileName = filePath.split('/')[-1]
# pp fileName
fileNameOnly = fileName.split('.')[0]
# pp fileNameOnly

puts 'tokenizing file'
tokenList = Tokenizer.tokenizeFile(filePath)
# pp tokenList

puts 'assembling token list'
assembledTokens = m.assemble(tokenList)
# pp assembledTokens

puts 'linking Labels'
linkedTokens = m.link(assembledTokens)
# pp linkedTokens

puts 'creating binary'
bin = m.compile(linkedTokens)

outputFileName = options[:out] || "./bin/#{m::ArchName}/#{fileNameOnly}.#{m::ArchName}.bin"
outputPath     = File.dirname(outputFileName)

FileUtils.mkdir_p outputPath
f = File.open(outputFileName, "wb")
f.write bin.pack(m::PackCharm)

f.close