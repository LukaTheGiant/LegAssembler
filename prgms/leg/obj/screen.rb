module SCR
    PTR = 0xf8
    def self.printStatic(str)
        out = "
        push @6
        rmem %#{PTR} @6
"
        str.chars.each do |c|
            out+= "wcon @6 %#{c.ord}\nadd %1 @6 @6\n"
        end
        out += "wmem %#{PTR} @6\npop @6"
        return out
    end
end