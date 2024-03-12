require "erb"
require 'optparse'
require 'fileutils'
require_relative "obj/tokenizer"
require_relative "obj/assembler"
require_relative "obj/linker"
require_relative "obj/number"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb fileName [options]"

  opts.on("--arch [ARCH]", String)
  opts.on('-o', '--out [OutputFile]', String)
  opts.on('-v', '--verbose')
  opts.on('-a', '--asm')
  opts.on('-l', '--ln')
  opts.on('--list')
end.parse!(into:options)

options[:arch] = 'ove' unless options[:arch]
pp options if options[:verbose]

#this is bad, but im doing it anyway, it should be fine
$ASMOptionsHash = options
#i ALWAYS try to avoid global variables, but i make this ONE exception


case options[:arch]
when "ove"
  require_relative 'obj/arch/overture'
  m = Overture
when "oven"
  require_relative 'obj/arch/overtureNext'
  m = OvertureNext
else
 raise "Arch #{options[:arch]} is not supported"
end

filePath = ARGV[0]
filePath=filePath.gsub("\\","/") #patch to help with windows paths
fileName = filePath.split('/')[-1]
fileNameOnly = fileName.split('.')[0]
outputFileName = options[:out] || "./bin/#{fileNameOnly}.#{m::ArchName}"
outputPath     = File.dirname(outputFileName)



if (options[:asm].nil? && options[:ln].nil?)
  puts 'tokenizing file'
  tokenList = Tokenizer.tokenizeFile(filePath,options)
  pp tokenList if options[:verbose]

  puts 'assembling token list'
  assembledList = Assembler.fromArr tokenList, arch: m, verbose: options[:verbose]
  pp assembledList if options[:verbose]

  puts 'linking from assembled list'
  Linker.fromArr assembledList, arch: m, outFile: outputFileName, verbose: options[:verbose], list:options[:list]

  exit
end

if options[:asm]
  puts 'tokenizing file'
  tokenList = Tokenizer.tokenizeFile(filePath)
  pp tokenList if options[:verbose]

  puts 'assembling token list'
  assembledList = Assembler.fromArr tokenList, arch: m, verbose: options[:verbose]
  pp assembledList if options[:verbose]

  Assembler.outputFile assembledList, arch: m, verbose: options[:verbose], outFile: outputFileName
elsif options[:ln]
  Linker.fromFile filePath, outFile: outputFileName, arch: m,  verbose: options[:verbose], list:options[:list]
end


