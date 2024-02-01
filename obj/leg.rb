module LEG
  PackCharm = 'S*'
  ArchName = 'leg'
  BYTEMAP = {
    add: 0,
    sub:1,
    rmem: 8,
    wmem: 9,
    rcon: 10,
    wcon:11,
    div:12,
    mod:13,

    push:16,
    pop:17,

    jeq: 32,
    jne: 33,
    jc: 38,
    jnc: 39,

    call: 46,
    ret: 47,
  }
  Rules = {
    ldi: {
      proc: proc do |l|
        nums = [NumberDecode.decode(l[1]), NumberDecode.decode(l[2])]
        raise "LDI requires immediate first" if nums[0][:type] != :num
        raise "LDI requires Register second" if nums[1][:type] != :reg

        next { type: :inst, inst: :add, v1: nums[0], v2: NumberDecode.decode("#0"), v3: nums[1] }
      end,
    },
    mov: {
      proc: proc do |l|
        nums = [NumberDecode.decode(l[1]), NumberDecode.decode(l[2])]
        raise "MOV requires Register first" if nums[0][:type] != :reg
        raise "MOV requires Register second" if nums[1][:type] != :reg
        next { type: :inst, inst: :add, v1: nums[0], v2: NumberDecode.decode("#0"), v3: nums[1] }
      end,
    },
    jmp: {
      proc: proc do |l|
        zero = NumberDecode.decode("#0")
        next { type: :inst, inst: :jeq, v1: zero, v2: zero, v3: l[1] }
      end,
    },
    ret: {
      proc: proc do |l|
        zero = NumberDecode.decode("@0")
        next { type: :inst, inst: :ret, v1: zero, v2: zero, v3: zero }
      end,
    },
    push: {
      proc: proc do |l|
        zero = NumberDecode.decode("@0")
        next { type: :inst, inst: :push, v1: NumberDecode.decode(l[1]), v2: zero, v3: zero }
      end,
    },
    pop: {
      proc: proc do |l|
        zero = NumberDecode.decode("@0")
        next { type: :inst, inst: :pop, v1: zero, v2: zero, v3: NumberDecode.decode(l[1]) }
      end,
    },
  }

  Rules.default = {
    proc: proc do |lineSplit|
      next { type: :token, content: lineSplit }
    end,
  }

  ALU = [
    :add,
    :sub,
    :div,
    :mod,
  ]

  #OUTPUT IMPLIED ALU INSTRUCTIONS, things like writing to memory
  OIALU = [
    :wmem,
    :wcon,
  ]

  #SINGLE INPUT ALU INSTRUCTIONS,  things like reading from memory
  SIALU = [
    :rmem,
    :rcon,
  ]

  COND = [
    :jeq,
    :jne,
    :jlt,
    :jgt,
    :jge,
    :jle,
  ]

  #ICOND instructions just require a jump address because they are implied (like carry bit or calling a function)
  ICOND = [
    :jc,
    :jnc,
    :call,
  ]

  ALU.each do |i|
    Rules[i] = {
      proc: proc do |l|
        out = NumberDecode.decode(l[3])
        raise "ALU instructions require reqister at the end" unless out[:type] == :reg
        next { type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2: NumberDecode.decode(l[2]), v3: out }
      end,
    }
  end

  OIALU.each do |i|
    Rules[i] = {
      proc: proc do |l|
        next { type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2: NumberDecode.decode(l[2]), v3: NumberDecode.decode("%0") }
      end,
    }
  end

  SIALU.each do |i|
    Rules[i] = {
      proc: proc do |l|
        outreg = NumberDecode.decode(l[2])
        raise "#{i} requires Register second" if outreg[:type] != :reg
        next { type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2: NumberDecode.decode("%0"), v3: outreg }
      end,
    }
  end

  COND.each do |i|
    Rules[i] = {
      proc: proc do |l|
        next { type: :inst, inst: i, v1: NumberDecode.decode(l[1]), v2: NumberDecode.decode(l[2]), v3: l[3] }
      end,
    }
  end

  ICOND.each do |i|
    Rules[i] = {
      proc: proc do |l|
        zero = NumberDecode.decode("#0")
        next { type: :inst, inst: i, v1: zero, v2: zero, v3: l[1] }
      end,
    }
  end

  def self.assemble(t)
    t.tokenArray.each.with_index do |o, i|
      next unless o[:type] == :token

      typeSym = o[:content][0].to_sym

      # raise "#{typeSym} not supported for leg" if !(Rules.keys.include?(typeSym))
      t.replace(i, Rules[typeSym][:proc].call(o[:content]))
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
          e[argName] = { type: :num, value: labelHash[e[argName]] * 4 }
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
        raise "instruction not found in bytemap #{e[:inst]}" unless BYTEMAP.include?(e[:inst])
        out[i] = BYTEMAP[e[:inst]]
        out[i] |= 0b10000000 if e[:v1][:type] == :num
        out[i] |= 0b01000000 if e[:v2][:type] == :num
        out[i + 1] = e[:v1][:value]
        out[i + 2] = e[:v2][:value]
        out[i + 3] = e[:v3][:value] # Check if label exists? (comment for assembly error)
        i += 4
      end
    end

    return out
  end
end
