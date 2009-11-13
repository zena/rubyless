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
    #  var1.spouse.name == ''
    # "var1.spouse" would be the condition that could yield 'nil'.
    def cond
      @opts[:cond]
    end
    
    # raw result without nil checking:
    # "var1.spouse.name" instead of "(var1.spouse ? var1.spouse.name : nil)"
    def raw
      @opts[:raw] || self.to_s
    end
    
    # Append a typed string to build an argument list
    def append_argument(typed_string)
      append_opts(typed_string)
      if self.empty?
        replace(typed_string.raw)
      else
        replace("#{self.raw}, #{typed_string.raw}")
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