$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'parse_tree'

=begin rdoc
=end
module RubyLess
  VERSION = '0.1.0'
  
  def self.translate(string, helper)
    RubyLessProcessor.translate(string, helper)
  end
  
  class Number
    def self.safe_method?(signature)
      {
        [:"<=>", Number] => Boolean,
        [:==, Number] => Boolean,
        [:< , Number] => Boolean,
        [:> , Number] => Boolean,
        [:<=, Number] => Boolean,
        [:>=, Number] => Boolean,

        [:- , Number] => Number,
        [:+ , Number] => Number,
        [:* , Number] => Number,
        [:/ , Number] => Number,
        [:% , Number] => Number,

        [:"-@"]       => Number,
      }[signature]
    end
  end

  class Boolean
  end

  class TypedString < String
    attr_reader :klass

    def initialize(content = "", klass = [])
      replace(content)
      @klass = klass
    end

    def <<(typed_string)
      if self.empty?
        @klass = typed_string.klass
        replace(typed_string)
      elsif @klass.kind_of?(Array)
        @klass << typed_string.klass
        replace("#{self}, #{typed_string}")
      else
        @klass = [@klass, typed_string.klass]
        replace("#{self}, #{typed_string}")
      end
    end

    def safe_method?(signature)
      @klass.respond_to?(:safe_method?) ? @klass.safe_method?(signature) : nil
    end
  end

  class RubyLessProcessor < SexpProcessor
    attr_reader :ruby

    STRONG_PRECEDENCE = [:"<=>", :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%]
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
      exp.size > 1 ? t("[#{res}]", res.klass) : res
    end

    def process_vcall(exp)
      var_name = exp.shift.to_s
      var, klass = @helper.variable(var_name)
      unless var
        raise "Unknown variable '#{var_name}'."
      end
      t var, klass
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
      def t(content, klass = nil)
        TypedString.new(content, klass)
      end

      def method_call(receiver, exp)
        method = exp.shift
        if args = exp.shift rescue nil
          args = process args || []
          signature = [method] + [args.klass].flatten
        else
          args = []
          signature = [method]
        end

        if receiver
          raise "'#{receiver}' does not respond to '#{method}(#{args})'." unless klass = (receiver.safe_method?(signature) || @helper.any_safe_method?(signature))
          if STRONG_PRECEDENCE.include?(method)
            t "#{receiver}#{method}#{args}", klass
          elsif PREFIX_OPERATOR.include?(method)
            t "#{method.to_s[0..0]}#{receiver}", klass
          else
            args = "(#{args})" if args != []
            t "#{receiver}.#{method}#{args}", klass
          end
        else
          raise "Unknown method '#{method}(#{args})'." unless klass = @helper.safe_method?(signature)
          args = "(#{args})" if args != []
          t "#{method}#{args}", klass
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
  end
end
