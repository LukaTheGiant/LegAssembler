

module LEG
    BYTEMAP = {
        add: 0,
        rmem:8,
        wmem:9,

        jeq:32,
        jc:38,
        jnc:39,
    }
    Rules = {
        ldi: {
            proc: proc do |l|
                nums = [NumberDecode.decode(l[1]),NumberDecode.decode(l[2])]
                raise "LDI requires immediate first" if nums[0][:type] != :num
                raise "LDI requires Register second" if nums[1][:type] != :reg

                next {type: :inst, inst: :add, v1: nums[0],v2: NumberDecode.decode('#0'), v3: nums[1]}
            end
        },
        mov: {
            proc: proc do |l|
                nums = [NumberDecode.decode(l[1]),NumberDecode.decode(l[2])]
                raise "MOV requires Register first" if nums[0][:type] != :reg
                raise "MOV requires Register second" if nums[1][:type] != :reg
                next {type: :inst, inst: :add, v1:nums[0],v2:NumberDecode.decode("#0"),v3:nums[1]}
            end
        },
        jmp: {
            proc: proc do |l|
                zero = NumberDecode.decode('#0')
                next {type: :inst, inst: :jeq, v1: zero, v2: zero, v3:l[1]}
            end
        },
        wmem:{
            proc: proc do |l|
                next {type: :inst, inst: :wmem, v1: NumberDecode.decode(l[1]), v2: NumberDecode.decode(l[2]), v3:NumberDecode.decode("%0")}
            end
        },
        rmem:{
            proc: proc do |l|
                outreg = NumberDecode.decode(l[2])
                raise "RMEM requires Register second" if outreg[:type] != :reg
                next {type: :inst, inst: :rmem, v1: NumberDecode.decode(l[1]), v2:NumberDecode.decode("%0") , v3:outreg}
            end
        },
        jc:{
            proc: proc do |l|
                zero = NumberDecode.decode('#0')
                next {type: :inst, inst: :jc, v1: zero, v2: zero, v3:l[1]}
            end
        },
        jnc:{
            proc: proc do |l|
                zero = NumberDecode.decode('@0')
                next {type: :inst, inst: :jnc, v1: zero, v2: zero, v3:l[1]}
            end
        },
    }
    
    Rules.default = {
        proc: proc do |lineSplit|
            {type: :token, content: lineSplit}
        end
    }
    

    ALU = [
        :add,
        :sub,
    ]

    COND = [
        :jeq,
    ]

    ALU.each do |i|
        Rules[i] = {
            proc: proc do |l|
                out = NumberDecode.decode(l[3])
                raise "ALU instructions require reqister at the end" unless out[:type]==:reg
                next {type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2:NumberDecode.decode(l[2]), v3:out}
            end
        }
    end

    COND.each do |i|
        Rules[i] = {
            proc: proc do |l|
                next {type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2:NumberDecode.decode(l[2]), v3:l[3]}
            end
        }
    end

    def self.assemble(t)
        t.tokenArray.each.with_index do |o,i|
            next unless o[:type] == :token
            
            typeSym = o[:content][0].to_sym

            # raise "#{typeSym} not supported for leg" if !(Rules.keys.include?(typeSym))
            t.replace(i, Rules[typeSym][:proc].call(o[:content]))
        end
    end

    
    def self.link(t)
        #Remove labels and replace ALL name referances
        #By the end, all that should be left is instruction objects
        labelHash = {}
        #go through labels and give them values
        addr = 0
        t.tokenArray.each do |e|
            case e[:type]
            when :org
                addr= e[:addr][:value]
            when :inst
                addr += 1
            when :label
                labelHash[e[:name]] = addr
            when :token
                raise "Should assemble before linking: #{e}"
            end
        end

        #final pass
        t.filter {|x| x[:type]==:inst||x[:type]==:org}
        t.tokenArray.each do |e|
            [:v1,:v2,:v3].each do |argName| 
                if labelHash.include?(e[argName])
                    e[argName] = {type: :num, value: labelHash[e[argName]]*4}
                end
            end
        end
    end

    def self.compile(t)
        out = Array.new(0x10000, 0)
        i = 0

        t.tokenArray.each do |e|
            #org and inst is all thats left
            if e[:type]==:org
                i = e[:addr][:value]
            else
                raise "instruction not found in bytemap #{e[:inst]}" unless BYTEMAP.include?(e[:inst])
                out[i] = BYTEMAP[e[:inst]]
                out[i] |= 0b10000000 if e[:v1][:type]==:num
                out[i] |= 0b01000000 if e[:v2][:type]==:num
                out[i+1] = e[:v1][:value]
                out[i+2] = e[:v2][:value]
                out[i+3] = e[:v3][:value]
                i+=4
            end
        end

        return out
    end
end