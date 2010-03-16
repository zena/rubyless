require 'rubygems'
require 'ruby_parser'
require 'sexp_processor'

module RubyLess
  class RubyLessProcessor < SexpProcessor
    attr_reader :ruby

    INFIX_OPERATOR = ['<=>', '==', '<', '>', '<=', '>=', '-', '+', '*', '/', '%']
    PREFIX_OPERATOR   = ['-@']

    def self.translate(string, helper)
      sexp = RubyParser.new.parse(string)
      self.new(helper).process(sexp)
    end

    def initialize(helper)
      super()
      @helper = helper
      @indent = "  "
      self.auto_shift_type = true
      self.strict = true
      self.expected = TypedString
    end

    def process(exp)
      super
    rescue UnknownNodeError => err
      if err.message =~ /Unknown node-type :(.*?) /
        raise RubyLess::SyntaxError.new("'#{$1}' not available in RubyLess.")
      else
        raise RubyLess::SyntaxError.new(err.message)
      end
      # return nil if exp.nil?
      # method = exp.shift
      # send("process_#{method}", exp)
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
        raise RubyLess::SyntaxError.new("Error in conditional expression: '#{true_res}' and '#{false_res}' do not return results of same type (#{true_res.klass} != #{false_res.klass}).")
      end
      raise RubyLess::SyntaxError.new("Error in conditional expression.") unless true_res || false_res
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
        code.append_argument(process(exp.shift))
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
        raise RubyLess::NoMethodError.new("Unknown variable or method '#{var_name}'.")
      end
      method = opts[:method]
      if args = opts[:prepend_args]
        method = "#{method}(#{args.raw})"
      end
      t method, opts
    end

    def process_lit(exp)
      lit = exp.shift
      t lit.inspect, get_lit_class(lit.class)
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

    def process_hash(exp)
      result = []
      klass  = {}
      until exp.empty?
        key = exp.shift
        if [:lit, :str].include?(key.first)
          key = key[1]

          rhs = exp.shift
          type = rhs.first
          rhs = process rhs
          #rhs = "(#{rhs})" unless [:lit, :str].include? type # TODO: verify better!

          result << "#{key.inspect} => #{rhs}"
          klass[key] = rhs.klass
        else
          # ERROR: invalid key
          raise RubyLess::SyntaxError.new("Invalid key type for hash (should be a literal value, was #{key.first.inspect})")
        end
      end

      t "{#{result.join(', ')}}", :class => klass
    end

    def process_ivar(exp)
      method_call(nil, exp)
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
        method = exp.shift.to_s
        arg_sexp = args = exp.shift # rescue nil
        if arg_sexp
          args = process(arg_sexp)
          if args == ''
            args = nil
            signature = [method]
          else
            signature = [method] + [args.klass].flatten
          end
          # execution conditional
          cond = args ? (args.cond || []) : []
        else
          args = nil
          signature = [method]
          cond = []
        end

        if receiver
          if receiver.could_be_nil?
            cond += receiver.cond
          end
          opts = get_method(receiver, signature)
          method = opts[:method]
          if method == '/'
            t_if cond, "(#{receiver.raw}#{method}#{args.raw} rescue nil)", opts.merge(:nil => true)
          elsif INFIX_OPERATOR.include?(method)
            t_if cond, "(#{receiver.raw}#{method}#{args.raw})", opts
          elsif PREFIX_OPERATOR.include?(method)
            t_if cond, "#{method.to_s[0..0]}#{receiver.raw}", opts
          elsif method == '[]'
            t_if cond, "#{receiver.raw}[#{args.raw}]", opts
          else
            args = args_with_prepend(args, opts)
            args = "(#{args.raw})" if args
            t_if cond, "#{receiver.raw}.#{method}#{args}", opts
          end
        else
          opts = get_method(nil, signature)
          method = opts[:method]
          args = args_with_prepend(args, opts)
          args = "(#{args.raw})" if args
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

      def get_method(receiver, signature)
        klass = receiver ? receiver.klass : @helper

        type = klass.respond_to?(:safe_method_type) ? klass.safe_method_type(signature) : SafeClass.safe_method_type_for(klass, signature)

        if type.nil?
          # We try to match with the superclass of the arguments
        end
        raise RubyLess::NoMethodError.new(receiver, klass, signature) if !type || type[:class].kind_of?(Symbol) # we cannot send: no object.

        type[:class].kind_of?(Proc) ? type[:class].call(@helper, signature) : type
      end

      def get_lit_class(klass)
        unless lit_class = RubyLess::SafeClass.literal_class_for(klass)
          raise RubyLess::SyntaxError.new("#{klass} literal not supported by RubyLess.")
        end
        lit_class
      end

      def args_with_prepend(args, opts)
        if prepend_args = opts[:prepend_args]
          if args
            prepend_args.append_argument(args)
            prepend_args
          else
            prepend_args
          end
        else
          args
        end
      end
  end
end
