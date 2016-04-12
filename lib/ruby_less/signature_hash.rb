
module RubyLess
  class SignatureHash < Hash
    alias get []

    # This method is used *A LOT*, make sure it stays as fast as possible.
    def [](signature)
      if type = get(signature)
        # fastest: all keys are equal
        return type
      elsif signature.kind_of?(Array)
        size = signature.size
        static_types = true
        ancestors = signature.map do |k|
          if k.kind_of?(Symbol)
            [k]
          elsif k.kind_of?(Class) && k.name != '' && !k.name.nil?
            k.ancestors
          else
            static_types = false
            k.respond_to?(:ancestors) ? k.ancestors : [k]
          end
        end
        value = nil
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
            # insert in cache if the signature does not contain dynamic types
            # self[signature] = type if static_types
            # return type
            value = type
            break
          end
        end # each
        self[signature] = value if static_types
        return value
      end
      nil
    end
  end
end
