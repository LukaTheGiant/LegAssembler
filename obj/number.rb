module NumberDecode
    BASE = {
        '!' => 2,
        '#' => 16,
        '%' => 10,
        '@' => :reg,
    }

    def self.decode(s)
        raise "Invalid number" unless BASE.keys.include?(s[0])
        o = {}
        b = BASE[s[0]]
        if b == :reg
            o[:type] = :reg
            o[:value]= s[1..-1].to_i
            return o
        end
        o[:type] = :num
        o[:value]= s[1..-1].to_i(b)
        return o
    end

end