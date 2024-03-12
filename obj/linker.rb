module Linker
    def self.fromFile(filename, opts = {})
        f = File.open(filename, 'rb')
        filedata = f.read()
        arr = Marshal.load(filedata)
        fullArr = arr.map {|x| Marshal.load(x)}
        fromArr(fullArr, opts)
    end

    def self.fromArr(arr, opts = {})
      opts[:arch] = Overture unless opts[:arch]

      #from a list of hashes of program data, create a program file

      labelOps = {
        '+' => proc do |hash,match|
          next hash[:value] + NumberDecode.decode(match['offset'])[:value]
        end,
        '-' => proc do |hash,match|
          next hash[:value] - NumberDecode.decode(match['offset'])[:value]
        end,
        '*' => proc do |hash,match|
          next hash[:value] * NumberDecode.decode(match['offset'])[:value]
        end,
        '/' => proc do |hash,match|
          next hash[:value]/NumberDecode.decode(match['offset'])[:value]
        end,
        '<' => proc do |hash,match|
          next hash[:value] << NumberDecode.decode(match['offset'])[:value]
        end,
        '>' => proc do |hash,match|
          next hash[:value] >> NumberDecode.decode(match['offset'])[:value]
        end,
        '&' => proc do |hash,match|
          next hash[:value] & NumberDecode.decode(match['offset'])[:value]
        end,
        '|' => proc do |hash,match|
          next hash[:value] | NumberDecode.decode(match['offset'])[:value]
        end,
      }
      #Remove labels and replace ALL name referances
      #By the end, all that should be left is instructions and orgs
      labelHash = {}
      #go through labels and give them values
      softaddr = 0
      addr     = 0
      arr.each do |e|
        case e[:type]
        when :org
          addr = e[:addr][:value] unless e[:soft]
          softaddr = e[:addr][:value]
        when :inst, :db
          addr += 1
          softaddr +=1
        when :unsoft
          softaddr = addr
        when :label
          labelHash[e[:name]] = softaddr
        when :token
          raise "Should assemble before linking: #{e}"
        end
      end
      puts 'creating binary' if opts[:verbose]
      pp labelHash
  
      
  
      #final pass
      
      newList = arr.filter { |x| x[:type] == :inst || x[:type] == :org || x[:type] == :db}
      # pp newList if opts[:verbose]

      
      newList.each do |e| 
        [:v1, :v2, :v3, :addr, :value].each do |argName|
          next unless e.include?(argName)
          next unless e[argName].is_a? String
          #SEPERATE OFFSET
          pp e if opts[:verbose]
          labelOpMatch = labelOps.keys.map{|x| "\\#{x}"}.join('|')
          labelInvertedOpMatch = "[^#{labelOpMatch}]"
          matchRegex = /\A(?<label>#{labelInvertedOpMatch}*)((?<op>(#{labelOpMatch}))(?<offset>(\$|\^|\&|\%|\#|\!)\d*))?\z/
          match = matchRegex.match(e[argName])
          pp matchRegex if opts[:verbose]
          pp match if opts[:verbose]
          if labelHash.include?(match['label'])
            e[argName] = { type: :num, value: labelHash[match['label']] }
          end
          if labelOps.include?(match['op'])
            e[argName][:value] = labelOps[match['op']].call(e[argName],match)
          end
        end
      #   pp e if opts[:verbose]
      end
      
      if opts[:list]
        outputNumList(newList,opts)
      else
        outputFile(newList, opts)
      end
    end

    def self.outputFile(arr,opts = {})
        pp arr if opts[:verbose]
        out = Array.new(opts[:arch]::MAXROMSIZE, 0)
        i = 0
    
        arr.each do |e|
          pp e if opts[:verbose]
          #org and inst is all thats left
          if e[:type] == :org
            i = e[:addr][:value] & 0x3fff unless e[:soft]
          elsif e[:type] == :db
            out[i] = e[:value][:value]
            i+=1
          else
            puts "[WARN] DATA OVERWRITE AT #%04x / #{i}" % i if out[i] != 0
            out[i] = opts[:arch]::BinRules[e[:inst]].call(e)
            i+=1
          end
        end
        
        puts "creating file to output" if opts[:verbose]
        outputFileName = opts[:outFile] + '.bin'
        outputPath     = File.dirname(outputFileName)

        FileUtils.mkdir_p outputPath
        f = File.open(outputFileName, "wb")
        dataOut = out.pack(opts[:arch]::PackCharm)
        # pp dataOut if opts[:verbose]
        f.write dataOut

        f.close

    end

    def self.outputNumList(arr,opts = {})
        pp arr if opts[:verbose]
        out = Array.new(opts[:arch]::MAXROMSIZE, 0)
        i = 0
    
        arr.each do |e|
          pp e if opts[:verbose]
          #org and inst is all thats left
          if e[:type] == :org
            i = e[:addr][:value] & 0x3fff unless e[:soft]
          elsif e[:type] == :db
            out[i] = e[:value][:value]
            i+=1
          else
            puts "[WARN] DATA OVERWRITE AT #%04x / #{i}" % i if out[i] != 0
            out[i] = opts[:arch]::BinRules[e[:inst]].call(e)
            i+=1
          end
        end
        
        puts "creating file to output" if opts[:verbose]
        outputFileName = opts[:outFile] + '.txt'
        outputPath     = File.dirname(outputFileName)

        FileUtils.mkdir_p outputPath
        f = File.open(outputFileName, "w")
        dataOut = out.each_slice(8).to_a.map{|x| x.join(' ')}.join("\n")
        # pp dataOut if opts[:verbose]
        f.write dataOut

        f.close

    end
end