$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'parse_tree'
require 'SafeClass'
=begin rdoc
=end
module RubyLess
  VERSION = '0.1.0'
  
  def self.translate(string, helper)
    RubyLessProcessor.translate(string, helper)
  end
  
  class Boolean
  end
  
  class Number
    include SafeClass
    safe_method( [:==, Number] => Boolean, [:< , Number] => Boolean, [:> , Number] => Boolean, [:<=, Number] => Boolean, [:>=, Number] => Boolean,
                 [:- , Number] => Number,  [:+ , Number] => Number,  [:* , Number] => Number,  [:/ , Number] => Number,
                 [:% , Number] => Number,  [:"-@"]       => Number )
  end
  
  
  class Missing
    [:==, :< , :> , :<=, :>=, :"?"].each do |sym|
      define_method(sym) do |arg|
        false
      end
    end
    
    def to_s
      ''
    end
    
    def nil?
      true
    end
    
    def method_missing(*meth)
      self
    end
  end
  
  Nil = Missing.new

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
    
    def klass
      @opts[:class]
    end
    
    def could_be_nil?
      @opts[:nil]
    end
    
    # condition when 'could_be_nil' comes from a different method then the last one:
    # var1.spouse.name == ''
    # "var1.spouse" would be the condition that inserted 'could_be_nil?'.
    def cond
      @opts[:cond]
    end
    
    # raw result without nil checking:
    # "var1.spouse.name" instead of "(var1.spouse ? var1.spouse.name : nil)"
    def raw
      @opts[:raw] || self.to_s
    end

    def <<(typed_string)
      append_opts(typed_string)
      if self.empty?
        replace(typed_string.raw)
      else
        replace("#{self.raw}, #{typed_string.raw}")
      end
    end
    
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

  class RubyLessProcessor < SexpProcessor
    attr_reader :ruby

    INFIX_OPERATOR = [:"<=>", :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%]
    PREFIX_OPERATOR   = [:"-@"]

    def self.translate(string, helper)
      sexp = ParseTree.translate(string)
      self.new(helper).process(sexp)
    end

    def initialize(helper)
      super()
      @helper     = helper
      @indent     = "  "
      self.auto_shift_type = true
      self.strict = true
      self.expected = TypedString
    end

    def process_and(exp)
      t "(#{process(exp.shift)} and #{process(exp.shift)})", Boolean
    end

    def process_or(exp)
      t "(#{process(exp.shift)} or #{process(exp.shift)})", Boolean
    end

    def process_not(exp)
      t "not #{process(exp.shift)}", Boolean
    end
    
    def process_if(exp)
      cond      = process(exp.shift)
      true_res  = process(exp.shift)
      false_res = process(exp.shift)
      
      if true_res && false_res && true_res.klass != false_res.klass
        raise "Error in conditional expression: '#{true_res}' and '#{false_res}' do not return results of same type (#{true_res.klass} != #{false_res.klass})."
      end
      raise "Error in conditional expression." unless true_res || false_res
      opts = {}
      opts[:nil] = true_res.nil? || true_res.could_be_nil? || false_res.nil? || false_res.could_be_nil?
      opts[:class] = true_res ? true_res.klass : false_res.klass
      t "#{cond} ? #{true_res || 'nil'} : #{false_res || 'nil'}", opts
    end

    def process_call(exp)
      receiver_node_type = exp.first.nil? ? nil : exp.first.first
      receiver = process exp.shift

      # receiver = t("(#{receiver})", receiver.klass) if
      #   Ruby2Ruby::ASSIGN_NODES.include? receiver_node_type

      method_call(receiver, exp)
    end

    def process_fcall(exp)
      method_call(nil, exp)
    end

    def process_arglist(exp)
      code = t("")
      until exp.empty? do
        code << process(exp.shift)
      end
      code
    end

    def process_array(exp)
      res = process_arglist(exp)
      exp.size > 1 ? t("[#{res}]", res.opts) : res
    end

    def process_vcall(exp)
      var_name = exp.shift
      unless opts = get_method([var_name], @helper, false)
        raise "Unknown variable or method '#{var_name}'."
      end
      method = opts[:method] || var_name.to_s
      t method, opts
    end

    def process_lit(exp)
      t exp.shift.to_s, Number
    end

    def process_str(exp)
      t exp.shift.inspect, String
    end

    def process_dstr(exp)
      t "\"#{parse_dstr(exp)}\"", String
    end

    def process_evstr(exp)
      exp.empty? ? t('', String) : process(exp.shift)
    end

    private
      def t(content, opts = nil)
        if opts.nil?
          opts = {:class => String}
        elsif !opts.kind_of?(Hash)
          opts = {:class => opts}
        end
        TypedString.new(content, opts)
      end
      
      def t_if(cond, true_res, opts)
        if cond != []
          if cond.size > 1
            condition = "(#{cond.join(' && ')})"
          else
            condition = cond.join('')
          end
          
          # we can append to 'raw'
          if opts[:nil]
            # applied method could produce a nil value (so we cannot concat method on top of 'raw' and only check previous condition)
            t "(#{condition} ? #{true_res} : nil)", opts
          else
            # we can keep on checking only 'condition' and appending methods to 'raw'
            t "(#{condition} ? #{true_res} : nil)", opts.merge(:nil => true, :cond => cond, :raw => true_res)
          end
        else
          t true_res, opts
        end
      end

      def method_call(receiver, exp)
        method = exp.shift
        if args = exp.shift rescue nil
          args = process args || []
          signature = [method] + [args.klass].flatten ## FIXME: error prone !
          # execution conditional
          cond = args.cond || []
        else
          args = []
          signature = [method]
          cond = []
        end
        
        if receiver
          if receiver.could_be_nil?
            cond += receiver.cond
          end
          raise "'#{receiver}' does not respond to '#{method}(#{args.raw})'." unless opts = get_method(signature, receiver.klass)
          method = opts[:method] if opts[:method]
          if method == :/
            t_if cond, "(#{receiver.raw}#{method}#{args.raw} rescue nil)", opts.merge(:nil => true)
          elsif INFIX_OPERATOR.include?(method)
            t_if cond, "(#{receiver.raw}#{method}#{args.raw})", opts
          elsif PREFIX_OPERATOR.include?(method)
            t_if cond, "#{method.to_s[0..0]}#{receiver.raw}", opts
          else
            args = "(#{args.raw})" if args != []
            t_if cond, "#{receiver.raw}.#{method}#{args}", opts
          end
        else
          raise "Unknown method '#{method}(#{args.raw})'." unless opts = get_method(signature, @helper, false)
          method = opts[:method] if opts[:method]
          args = "(#{args.raw})" if args != []
          t_if cond, "#{method}#{args}", opts
        end
      end

      def parse_dstr(exp, in_regex = false)
        res = escape_str(exp.shift, in_regex)

        while part = exp.shift
          case part.first
          when :str then
            res << escape_str(part.last, in_regex)
          else
            res << '#{' << process(part) << '}'
          end
        end
        res
      end

      def escape_str(str, in_regex = false)
        res = str.gsub(/"/, '\"').gsub(/\n/, '\n')
        res.gsub!(/\//, '\/') if in_regex
        res
      end
      
      def get_method(signature, receiver, is_method = true)
        res = receiver.respond_to?(:safe_method?) ? receiver.safe_method?(signature) : @helper.class.safe_method_for?(receiver, signature)
        res = res.call(@helper) if res.kind_of?(Proc)
        res
      end
  end
end
