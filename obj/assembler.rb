module Assembler 
    PackCharm = 'A*'
    def self.fromArr(arr, opts = {})
        opts[:arch] = Overture unless opts[:arch]

        out = []
        
        arr.each do |e|
            pp e if opts[:verbose]
            unless e[:type] == :token
                out << e
                next
            end
            instructionSym = e[:content][0].to_sym
            validInput = opts[:arch].canAssemble? instructionSym
            raise "#{opts[:arch]} does not support the instruction #{instructionSym}" unless validInput

            out << opts[:arch].assemble(e)
        end

        out.flatten!

        return out
    end

    def self.outputFile(arr, opts = {})
        puts "creating file to output" if opts[:verbose]
        outputFileName = opts[:outFile] + '.out'
        outputPath     = File.dirname(outputFileName)

        FileUtils.mkdir_p outputPath
        f = File.open(outputFileName, "wb")
        dataOut = arr.map{|x| Marshal.dump x }
        pp dataOut if opts[:verbose]
        f.write Marshal.dump dataOut

        f.close
    end
end