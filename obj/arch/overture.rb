module Overture
  PackCharm = 'C*'
  ArchName = "ove"

  InstructionTypes = {
    imm: 0b00,
    alu: 0b01,
    mov: 0b10,
    jmp: 0b11,
  }

  ALUMAP = {
    or: 0,
    nand: 1,
    nor: 2,
    and: 3,
    add: 4,
    sub: 5,
    shr: 6,
    shl: 7,
  }

  CONDMAP = {
    nop: 0,
    jez: 1,
    jlz: 2,
    jle: 3,
    jmp: 4,
    jnz: 5,
    jge: 6,
    jgt: 7,
  }

  LexRules = {
    mov: {
      proc: proc do |l|
        nums = [NumberDecode.decode(l[1]), NumberDecode.decode(l[2])]
        raise "mov needs 2 registers" if (nums.filter { |x| x[:type] == :reg }).empty?
        next { type: :inst, inst: :mov, v1: nums[0], v2: nums[1] }
      end,
    },
    ldi: {
      proc: proc do |l|
        # pp l
        num = NumberDecode.decode(l[1])
        # pp num
        outReg = nil
        outReg = NumberDecode.decode(l[2]) if l.length > 2
        raise "Ldi[2] output register needs to be a register" if !(outReg.nil?) && outReg[:type] != :reg
        out = []
        unless num.is_a?(String)
          raise "ldi needs value" unless num[:type] == :num
          puts "[WARN] DATA LOSS FOR IMMEDIATE OVER #{0b00111111}" if num[:value] > 0b00111111
        end
        

        out << { type: :inst, inst: :imm, v1: num }
        out << { type: :inst, inst: :mov, v1: NumberDecode.decode("@0"), v2: outReg } unless outReg.nil?
        next out
      end,
    },
  }

  CompRules = {
    mov: proc do |t|
      next (InstructionTypes[:mov] << 6) | (t[:v1][:value] << 3) | (t[:v2][:value])
    end,
    alu: proc do |t|
      next (InstructionTypes[:alu] << 6) | t[:v1][:value]
    end,
    jmp: proc do |t|
      next (InstructionTypes[:jmp] << 6) | (t[:v2] << 3) | t[:v1]
    end,
    imm: proc do |t|
      # pp t
      puts "[WARN] IMMEDIATE VALUE TRUNCATED, UNEXPECTED RESULTS MAY OCCUR" if t[:v1][:value]&0b11000000 != 0
      next t[:v1][:value] & 0b00111111
    end,
  }

  def self.assemble(tokenlist)
    out = []
    i = -1
    tokenlist.each do |e|

      unless e[:type] == :token
        out << e
        next
      end

      instSym = e[:content][0].to_sym
      if LexRules.include? instSym
        token = LexRules[instSym][:proc].call(e[:content])
      elsif ALUMAP.include? instSym
        token = { type: :inst, inst: :alu, v1: {value: ALUMAP[instSym]} }
      elsif CONDMAP.include? instSym
        token = []
        match = /j\w{2}.* (?<cflag>(a|o)(n|!)?c)/.match(e[:content].join(' ')) #this regex seperates the cond carry from the string
        e[:content].pop if match
        token << { type: :inst, inst: :imm, v1: e[:content][1] } if e[:content].length > 1 
        jmpInst = { type: :inst, inst: :jmp, v1: CONDMAP[instSym], v2: 0 }
        token << jmpInst

        jmpInst[:v2] = condCarry(match) if match
      else
        token = e
      end
      out << token
    end
    out.flatten!
    return out
  end

  def self.link(tokenList)
    #Remove labels and replace ALL name referances
    #By the end, all that should be left is instructions and orgs
    labelHash = {}
    #go through labels and give them values
    addr = 0
    tokenList.each do |e|
      # pp e
      case e[:type]
      when :org
        addr = e[:addr][:value]
      when :inst
        addr += 1
      when :label
        puts "[WARN] LABEL #{e[:name]} WILL BE TRUNCATED, UNEXPECTED BHAVIOR MAY OCCUR" if addr&0b11000000 != 0
        labelHash[e[:name]] = addr
      when :db
        addr += 1
      when :token
        raise "Should assemble before linking: #{e}"
      end
    end
    pp labelHash

    #final pass
    newList = tokenList.filter { |x| x[:type] == :inst || x[:type] == :org || x[:type] == :db}
    newList.each do |e|
      [:v1, :v2, :v3].each do |argName|
        next unless e.include?(argName)
        if labelHash.include?(e[argName])
          e[argName] = { type: :num, value: labelHash[e[argName]] }
        end
      end
    end
    return newList
  end

  def self.compile(tokenList)
    out = Array.new(0x8000, 0)
    i = 0

    tokenList.each do |e|
      #org and inst is all thats left
      if e[:type] == :org
        i = e[:addr][:value] & 0x3fff unless e[:soft]
      elsif e[:type] == :db
        out[i] = e[:value][:value]
        i+=1
      else
        out[i] = CompRules[e[:inst]].call(e)
        i+=1
      end
      
    end

    return out
  end

  def self.condCarry(m)
    out = 0b010
    raise "invalid carry addon for jump instruction" if m[:cflag].length > 3 || m[:cflag].length < 2
    f = m[:cflag]
    if f.length == 3
      if (f[1] != "!") && (f[1] != "n")
        raise "invalid carry addon for jump instruction"
      end
      out |= 0b100
      f.sub!("n", "")
      f.sub!("!", "")
    end
    case f[0]
    when "a"
      out |= 0b000
    when "o"
      out |= 0b001
    else
      raise "invalid carry addon for jump instruction"
    end

    raise "invalid carry addon for jump instruction" unless f[1] == "c"
    return out
  end
end
