module RubyLess

  # This is a special kind of string containing ruby code that retains some information from the
  # elements that compose it.
  class TypedString < String
    attr_reader :klass, :opts

    def initialize(content = "", opts = nil)
      opts ||= {:class => String}
      replace(content)
      @opts = opts.dup
      if could_be_nil? && !@opts[:cond]
        @opts[:cond] = [self.to_s]
      end
    end

    # Resulting class of the evaluated ruby code if it is not nil.
    def klass
      @opts[:class]
    end

    # Returns true if the evaluation of the ruby code represented by the string could be 'nil'.
    def could_be_nil?
      @opts[:nil]
    end

    # Condition that could yield a nil result in the whole expression.
    # For example in the following expression:
    #  node.spouse.name == ''
    # "node.spouse" would be the condition that could yield 'nil'.
    def cond
      @opts[:cond]
    end
    
    # Return the literal value (string before inspect, number)
    def literal
      @opts[:literal]
    end

    # List of typed_strings that form the argument list. This is only used
    # to resolve nil when the receiver of the arguments accepts nil values.
    def list
      @list ||= []
    end

    # Hash arguments. This is only used to resolve parameter insertion with
    # append_hash.
    def hash
      @hash ||= {}
    end

    # Used to keep hash order (this is useful for testing).
    def keys
      @hash_keys ||= []
    end

    # raw result without nil checking:
    # "node.spouse.name" instead of "(node.spouse ? node.spouse.name : nil)"
    def raw
      @opts[:raw] || self.to_s
    end

    # Append a typed string to build an argument list
    def append_argument(typed_string)
      self.list << typed_string

      append_opts(typed_string)
      if self.empty?
        replace(typed_string.raw)
      else
        replace("#{self.raw}, #{typed_string.raw}")
      end
    end

    def rebuild_arguments
      replace(list.map {|arg| arg.raw}.join(', ')) if @list
    end

    def set_hash(key, value)
      self.hash[key] = value
      self.keys << key unless self.keys.include?(key)
      @opts[:class] = {} unless self.klass.kind_of?(Hash)
      self.klass[key] = value.klass
    end

    def rebuild_hash
      if @hash
        result = []
        @hash_keys.each do |k|
          result << "#{k.inspect} => #{@hash[k]}"
        end
        replace "{#{result.join(', ')}}"
      end
    end

    private
      def append_opts(typed_string)
        if self.empty?
          @opts = typed_string.opts.dup
        else
          if klass.kind_of?(Array)
            klass << typed_string.klass
          else
            @opts[:class] = [klass, typed_string.klass]
          end
          append_cond(typed_string.cond) if typed_string.could_be_nil?
        end
      end

      def append_cond(condition)
        @opts[:cond] ||= []
        @opts[:cond] += [condition].flatten
        @opts[:cond].uniq!
      end
  end
end