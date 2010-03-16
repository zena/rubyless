
module RubyLess
  class SignatureHash < Hash
    alias get []

    def [](signature)
      if type = get(signature)
        # fastest: all keys are equal
        return type
      elsif signature.kind_of?(Array)
        size = signature.size
        ancestors = signature.map {|k| k.kind_of?(Class) ? k.ancestors : [k]}

        each do |key, type|
          next unless key.size == size
          ok = true
          key.each_with_index do |k, i|
            if !ancestors[i].include?(k)
              ok = false
              break
            end
          end
          if ok
            # insert in cache
            self[signature] = type
            return type
          end
        end
      end
      nil
    end
  end
end
