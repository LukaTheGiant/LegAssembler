module Overture
  PackCharm = 'C*'
  ArchName = "ove"
  MAXROMSIZE = 0x8000

  InstructionTypes = {
    imm: 0b00,
    alu: 0b01,
    mov: 0b10,
    jmp: 0b11,
  }

  ALUMODES = {
    default: 0,
    acc: 0b01,
    alt: 0b10
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

  SpecialRules = {
    mov: proc do |l|
      pp l if $ASMOptionsHash[:verbose]
      nums = [NumberDecode.decode(l[1]), NumberDecode.decode(l[2])]
      raise "mov needs 2 registers" if (nums.filter { |x| x[:type] == :reg }).empty?
      next { type: :inst, inst: :mov, v1: nums[0], v2: nums[1] }
    end,

    ldi: proc do |l|
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
  }

  BinRules = {
    mov: proc do |t|
      next (InstructionTypes[:mov] << 6) | (t[:v1][:value] << 3) | (t[:v2][:value])
    end,
    alu: proc do |t|
      next (InstructionTypes[:alu] << 6) | t[:mode]<< 3 | t[:v1][:value]
    end,
    jmp: proc do |t|
      next (InstructionTypes[:jmp] << 6) | (t[:v2] << 3) | t[:v1]
    end,
    imm: proc do |t|
      pp t if $ASMOptionsHash[:verbose]
      puts "[WARN] IMMEDIATE VALUE TRUNCATED, UNEXPECTED RESULTS MAY OCCUR" if t[:v1][:value]&0b11000000 != 0
      next t[:v1][:value] & 0b00111111
    end,
  }

  IsALUInst = proc do |sym|
    next ALUMAP.include? sym
  end
  IsCONDInst = proc do |sym|
    next CONDMAP.include? sym
  end
  IsSpecialRule = proc do |sym|
    next SpecialRules.include? sym
  end

  def self.canAssemble?(sym)
    out = false
    out |= IsALUInst.call(sym)
    out |= IsCONDInst.call(sym)
    out |= IsSpecialRule.call(sym)

    return out
  end

  def self.assemble(token)
    instSym = token[:content][0].to_sym
    case instSym
    when IsSpecialRule
      out = SpecialRules[instSym].call(token[:content])
    when IsALUInst
      mode = 0
      token[:content].each do |t|
        if ALUMODES.include?(t.to_sym)
          mode |= ALUMODES[t.to_sym]
        end
      end
      out = { type: :inst, inst: :alu, v1: {value: ALUMAP[instSym]}, mode: mode }
    when IsCONDInst
      out = []
      pp token if $ASMOptionsHash[:verbose]
      match = /j\w{2}.* (?<cflag>(a|o)(n|!)?c)/.match(token[:content].join(' ')) #this regex seperates the cond carry from the string
      token[:content].pop if match
      out << { type: :inst, inst: :imm, v1: token[:content][1] } if token[:content][1]
      jmpInst = { type: :inst, inst: :jmp, v1: CONDMAP[instSym], v2: 0 }
      out << jmpInst

      jmpInst[:v2] = condCarry(match) if match
    else
      out = e
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
