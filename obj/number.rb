module NumberDecode
  BASE = {
    "!" => 2,
    '^' => 2,
    "#" => 16,
    "%" => 10,
    "@" => :reg,
    "$" => :label,
    "\""=> :string,
  }

  def self.decode(s)
    raise "Invalid number" unless BASE.keys.include?(s[0])
    o = {}
    b = BASE[s[0]]
    if b == :reg
      o[:type] = :reg
      o[:value] = s[1..-1].to_i
      return o
    elsif b == :string
      str = s[1..-2]
      return str.chars.map{|x| x.ord}.map{|x| {type: :num, value: x}}
    elsif b == :label
      return s[1..-1]
    end
    o[:type] = :num
    o[:value] = s[1..-1].to_i(b)
    return o
  end
end
