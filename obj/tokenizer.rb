MYOWNTOPLEVEL = binding
def fileRequire(file)
  require "./prgms/obj/#{file}"
end
class Tokenizer
  @@filesDone = []
  attr_reader :tokenArray, :labelRef

  Rules = {
    label: {
      proc: proc do |l|
        next { type: :label, name: l[1] }
      end,
    },
    org: {
      proc: proc do |l|
        value = NumberDecode.decode(l[1])
        raise "LDI requires immediate first" if value[:type] != :num
        next { type: :org, addr: value }
      end,
    },
    include: {
      proc: proc do |l|
        next [] if @@filesDone.include?(l[1])
        t = Tokenizer.new
        t.tokenizeFile("./prgms/#{l[1]}.asm")
        @@filesDone << l[1]
        next t.tokenArray
      end,
    },
  }

  Rules.default = {
    proc: proc do |lineSplit|
      { type: :token, content: lineSplit }
    end,
  }

  def initialize()
    @tokenArray = []
  end

  def tokenizeFile(fileName)
    file = File.read(fileName)

    tem = ERB.new file

    fileLines = tem.result(MYOWNTOPLEVEL).split("\n")
    fileLines.each do |line|
      tokenizeLine(line) unless line == ""
    end
  end

  def tokenizeLine(line)
    i = line.split(";")
    s = i[0].split()
    o = nil
    if s.length > 0
      o = Rules[s[0].to_sym][:proc].call(s)
    end
    push(o)
  end

  def push(o)
    return if o.nil?

    @tokenArray << o
    @tokenArray.flatten!
    return o.length if o.respond_to?(:length)
  end

  def replace(i, o)
    @tokenArray[i] = o
    @tokenArray.flatten!
    return o.length if o.respond_to?(:length)
  end

  def suffix(i, o)
    @tokenArray.insert(i, o)
    @tokenArray.flatten!
    return o.length if o.respond_to?(:length)
  end

  def postfix(i, o)
    @tokenArray.insert(i + 1, o)
    @tokenArray.flatten!
    return o.length if o.respond_to?(:length)
  end

  def filter(&block)
    @tokenArray.filter!(&block)
  end
end
