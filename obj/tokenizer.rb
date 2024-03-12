MYOWNTOPLEVEL = binding
module Tokenizer
  @@filesDone = []
  Rules = {
    label: {
      proc: proc do |l|
        next { type: :label, name: l[1] }
      end,
    },
    org: {
      proc: proc do |l|
        soft = false
        value = NumberDecode.decode(l[1])
        soft = true if l.length>2 && l[2] == "soft"
        raise "labels in org not supported yet" if value.is_a? String
        raise "org value must be a number" unless value[:type]==:num
        next { type: :org, addr: value, soft: soft}
      end,
    },
    unsoft: {
      proc: proc do |l|
        next { type: :unsoft }
      end,
    },
    include: {
      proc: proc do |l|
        next [] if @@filesDone.include?(l[1])
        next tokenizeFile("#{l[1]}")
      end,
    },
    db: {
      proc: proc do |l|
        values = l[1..-1].map {|x| NumberDecode.decode(x)}
        values.flatten!
        next values.map {|x| {type: :db, value: x}}
      end
    },
  }

  Rules.default = {
    proc: proc do |lineSplit|
      { type: :token, content: lineSplit }
    end,
  }

  def self.tokenizeFile(fileName, opts = {})
    tokenlist = []
    file = File.read(fileName)

    tem = ERB.new file

    fileLines = tem.result(MYOWNTOPLEVEL).split("\n")
    i=1
    fileLines.each do |line|
      token = tokenizeLine(line, opts) unless line == ""
      tokenlist << token if token
      i+=1
    end
    tokenlist.flatten!
    return tokenlist
  end

  def self.tokenizeLine(line, opts ={})
    i = line.split(";")
    s = i[0].scan(/(?:"|')[\w\s]*(?:"|')|[^\s]+/) if i[0]
    return unless s #return early if there is no content to tokenize
    s.flatten!
    # pp s
    o = nil
    if s.length > 0
      o = Rules[s[0].to_sym][:proc].call(s)
    end
    return o
  end
end
