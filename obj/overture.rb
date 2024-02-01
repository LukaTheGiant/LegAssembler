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
        num = NumberDecode.decode(l[1])
        outReg = nil
        outReg = NumberDecode.decode(l[2]) if l.length > 2
        raise "Ldi[2] output register needs to be a register" if !(outReg.nil?) && outReg[:type] != :reg
        out = []
        raise "ldi needs value" unless num[:type] == :num
        puts "[WARN] DATA LOSS FOR IMMEDIATE OVER #{0b00111111}" if num[:value] > 0b00111111

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
      puts "[WARN] IMMEDIATE VALUE TRUNCATED, UNEXPECTED RESULTS MAY OCCUR" if t[:v1][:value]&0b11000000 != 0
      next t[:v1][:value] & 0b00111111
    end,
  }

  def self.assemble(t)
    i = -1
    t.tokenArray.each do |e|
      i += 1

      next unless e[:type] == :token

      instSym = e[:content][0].to_sym
      if LexRules.include? instSym
        token = LexRules[instSym][:proc].call(e[:content])
      elsif ALUMAP.include? instSym
        token = { type: :inst, inst: :alu, v1: {value: ALUMAP[instSym]} }
      elsif CONDMAP.include? instSym
        token = []
        token << { type: :inst, inst: :imm, v1: e[:content][1] } if e[:content].length > 1
        token << { type: :inst, inst: :jmp, v1: CONDMAP[instSym], v2: 0 }
        token[1][:v2] = condCarry(e[:content]) if e[:content].length > 2
      else
        token = e
      end
      t.replace(i, token)
    end
  end

  def self.link(t, inject = {})
    #Remove labels and replace ALL name referances
    #By the end, all that should be left is instructions and orgs
    labelHash = {}
    #go through labels and give them values
    addr = 0
    t.tokenArray.each do |e|
      case e[:type]
      when :org
        addr = e[:addr][:value]
      when :inst
        addr += 1
      when :label
        puts "[WARN] LABEL #{e[:name]} WILL BE TRUNCATED, UNEXPECTED BHAVIOR MAY OCCUR" if addr&0b11000000 != 0
        labelHash[e[:name]] = addr
      when :token
        raise "Should assemble before linking: #{e}"
      end
    end

    #final pass
    t.filter { |x| x[:type] == :inst || x[:type] == :org }
    t.tokenArray.each do |e|
      [:v1, :v2, :v3].each do |argName|
        next unless e.include?(argName)
        if labelHash.include?(e[argName])
          e[argName] = { type: :num, value: labelHash[e[argName]] }
        end
      end
    end
  end

  def self.compile(t)
    out = Array.new(0x10000, 0)
    i = 0

    t.tokenArray.each do |e|
      #org and inst is all thats left
      if e[:type] == :org
        i = e[:addr][:value]
      else
        out[i] = CompRules[e[:inst]].call(e)
        i+=1
      end
      
    end

    return out
  end

  def self.condCarry(l)
    out = 0b010
    raise "invalid carry addon for jump instruction" if l[2].length > 3 || l[2].length < 2
    if l[2].length == 3
      if (l[2][1] != "!") && (l[2][1] != "n")
        raise "invalid carry addon for jump instruction"
      end
      out |= 0b100
      l[2].sub!("n", "")
      l[2].sub!("!", "")
    end
    case l[2][0]
    when "a"
      out |= 0b000
    when "o"
      out |= 0b001
    else
      raise "invalid carry addon for jump instruction"
    end

    raise "invalid carry addon for jump instruction" unless l[2][1] == "c"
    return out
  end
end
