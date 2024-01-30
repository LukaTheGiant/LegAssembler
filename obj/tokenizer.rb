class Tokenizer
    attr_reader :tokenArray, :labelRef

    Rules = {
        label: {
            proc: proc do |l|
                next {type: :label, name: l[1]}
            end,
        },
        org: {
            proc: proc do |l|
                value = NumberDecode.decode(l[1])
                raise "LDI requires immediate first" if value[:type] != :num
                next {type: :org, addr: value}
            end
        },
        const: {
            proc: proc do |l|
                {type: :const, name:l[1], value: NumberDecode.decode(l[2])}
            end
        }
    }

    Rules.default = {
        proc: proc do |lineSplit|
            {type: :token, content: lineSplit}
        end
    }

    def initialize()
        @consts = {}
        @labelRef   = {}
        @tokenArray = []
    end

    def tokenizeFile(fileName)
        file = File.read(fileName)

        tem = ERB.new file

        fileLines = tem.result.split("\n")
        fileLines.each do | line |
            tokenizeLine(line) unless line== ''
        end
    end

    def tokenizeLine(line)
        i = line.split(';')
        s = i[0].split()
        o = nil
        if s.length>0
            o = Rules[s[0].to_sym][:proc].call(s)
        end
        push(o)
    end

    def addLabelRef(name,index)
        @labelRef[name] = {} if @labelRef[name].nil?
        @labelRef[name] << index
    end

    def push(o) 
        return if o.nil?

        case o[:type]
        when :label
            @labelRef[:name]=[]
        when :const
            @consts[o[:name]]=o[:value]
        end

        @tokenArray << o
        @tokenArray.flatten!
    end
    def replace(i,o)
        @tokenArray[i] = o
        @tokenArray.flatten!
    end
    def suffix(i,o)
        @tokenArray.insert(i,o)
        @tokenArray.flatten!
    end
    def postfix(i,o)
        @tokenArray.insert(i+1,o)
        @tokenArray.flatten!
    end

    def filter(&block)
        @tokenArray.filter!(&block)
    end

end