require 'rubygems'
require 'ruby_parser'
require 'sexp_processor'

module RubyLess
  class RubyLessProcessor < SexpProcessor
    attr_reader :ruby

    INFIX_OPERATOR = ['<=>', '==', '<', '>', '<=', '>=', '-', '+', '*', '/', '%']
    PREFIX_OPERATOR   = ['-@']

    def self.translate(receiver, string)
      if sexp = RubyParser.new.parse(string)
        res = self.new(receiver).process(sexp)
        if res.klass.kind_of?(Hash)
          res.opts[:class] = Hash
        end
        res
      elsif string.size == 0
        ''
      else
        raise RubyLess::SyntaxError.new("Syntax error")
      end
    rescue Racc::ParseError => err
      raise RubyLess::SyntaxError.new(err.message)
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

    def process_const(exp)
      const_name = exp.pop.to_s
      if opts = @helper.respond_to?(:safe_const_type) ? @helper.safe_const_type(const_name) : nil
        t opts[:method], opts
      else
        raise RubyLess::Error.new("Unknown constant '#{const_name}'.")
      end
    end

    def process_true(*args)
      t 'true', {:class => Boolean, :literal => true}
    end

    def process_false(*args)
      t 'false', {:class => Boolean, :literal => false}
    end

    def process_nil(*args)
      t 'nil', {:class => NilClass, :literal => nil, :nil => true}
    end

    def process_and(exp)
      t "(#{process(exp.shift)} and #{process(exp.shift)})", Boolean
    end

    def process_or(exp)
      left, right = process(exp.shift), process(exp.shift)
      if left.klass == right.klass
        t "(#{left} or #{right})", :class => right.klass, :nil => right.could_be_nil?
      else
        t "(#{left} or #{right})", Boolean
      end
    end

    def process_not(exp)
      t "not #{process(exp.shift)}", Boolean
    end

    def process_if(exp)
      cond      = process(exp.shift)
      true_res  = process(exp.shift)
      false_res = process(exp.shift)

      if true_res && false_res
        if true_res.klass != false_res.klass
          if true_res.klass == NilClass
            # Change true_res to false_res class (could_be_nil? is true)
            true_res.opts[:class] = false_res.klass
          elsif false_res.klass == NilClass
            # Change false_res to true_res class (could_be_nil? is true)
            false_res.opts[:class] = true_res.klass
          else
            raise RubyLess::SyntaxError.new("Error in conditional expression: '#{true_res}' and '#{false_res}' do not return results of same type (#{true_res.klass} != #{false_res.klass}).")
          end
        end
      end
      raise RubyLess::SyntaxError.new("Error in conditional expression.") unless true_res || false_res
      opts = {}
      opts[:nil] = true_res.nil? || true_res.could_be_nil? || false_res.nil? || false_res.could_be_nil?
      opts[:class] = true_res ? true_res.klass : false_res.klass
      t "#{cond} ? #{true_res || 'nil'} : #{false_res || 'nil'}", opts
    end

    def process_call(exp)
      unless receiver = process(exp.shift)
        receiver = @helper.kind_of?(TypedString) ? @helper : nil
      end

      method_call(receiver, exp)
    end

    def process_fcall(exp)
      method_call(@helper.kind_of?(TypedString) ? @helper : nil, exp)
    end

    def process_arglist(exp)
      code = t("")
      until exp.empty? do
        code.append_argument(process(exp.shift))
      end
      code
    end

    def process_array(exp)
      literal = true
      list    = []
      classes = []
      while !exp.empty?
        res = process(exp.shift)
        content_class ||= res.opts[:class]
        unless res.opts[:class] <= content_class
          classes = list.map { content_class.name } + [res.opts[:class].name]
          raise RubyLess::Error.new("Mixed Array not supported ([#{classes * ','}]).")
        end
        list << res
      end

      res.opts[:class] = [content_class] # Array
      res.opts[:elem] = content_class
      t "[#{list * ','}]", res.opts.merge(:literal => nil)
    end

    # Is this used ?
    def process_vcall(exp)
      var_name = exp.shift
      unless opts = get_method(nil, [var_name])
        raise RubyLess::Error.new("Unknown variable or method '#{var_name}'.")
      end
      method = opts[:method]
      if args = opts[:prepend_args]
        method = "#{method}(#{args.raw})"
      end
      t method, opts
    end

    def process_lit(exp)
      lit = exp.shift
      t lit.inspect, get_lit_class(lit)
    end

    def process_str(exp)
      lit = exp.shift
      t lit.inspect, :class => String, :literal => lit
    end

    def process_dstr(exp)
      t "\"#{parse_dstr(exp)}\"", String
    end
    
    def process_dot2(exp)
      a = process(exp.shift)
      b = process(exp.shift)
      t "(#{a}..#{b})", Range
    end

    def process_evstr(exp)
      exp.empty? ? t('', String) : process(exp.shift)
    end

    def process_hash(exp)
      result = t "", String
      until exp.empty?
        key = exp.shift
        if [:lit, :str].include?(key.first)
          key = key[1]

          rhs = exp.shift
          type = rhs.first
          rhs = process rhs
          #rhs = "(#{rhs})" unless [:lit, :str].include? type # TODO: verify better!
          result.set_hash(key, rhs)
        else
          # ERROR: invalid key
          raise RubyLess::SyntaxError.new("Invalid key type for hash (should be a literal value, was #{key.first.inspect})")
        end
      end
      result.rebuild_hash
      result
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

        if receiver && receiver.klass.kind_of?(Hash)
          # resolve now
          if signature.first == '[]' && klass = receiver.klass[args.literal]
            return receiver.hash[args.literal]
          else
            # safe_method_type on Hash... ?
            receiver = TypedString.new(receiver, Hash)
            opts = get_method(receiver, signature)
          end
        else
          opts = get_method(receiver, signature)
        end

        # method type can rewrite receiver
        if opts[:receiver]
          if receiver
            receiver = "#{receiver}.#{opts[:receiver]}"
          else
            receiver = opts[:receiver]
          end
        end

        if receiver
          method_call_with_receiver(receiver, args, opts, cond, signature)
        else
          method = opts[:method]
          args = args_with_prepend(args, opts)

          if (proc = opts[:pre_processor]) && !args.list.detect {|a| !a.literal}
            if proc.kind_of?(Proc)
              res = proc.call(*([receiver] + args.list.map(&:literal)))
            else
              res = @helper.send(proc, *args.list.map(&:literal))
            end

            return res.kind_of?(TypedString) ? res : t(res.inspect, :class => String, :literal => res)
          end

          if opts[:accept_nil]
            method_call_accepting_nil(method, args, opts)
          else
            args = "(#{args.raw})" if args
            t_if cond, "#{method}#{args}", opts
          end
        end
      end

      def method_call_accepting_nil(method, args, opts)
        if args
          args = args.list.map do |arg|
            if !arg.could_be_nil? || arg.raw == arg.cond.to_s
              arg.raw
            else
              "(#{arg.cond} ? #{arg.raw} : nil)"
            end
          end.join(', ')

          t "#{method}(#{args})", opts
        else
          t method, opts
        end
      end

      def method_call_with_receiver(receiver, args, opts, cond, signature)
        method = opts[:method]
        arg_list = args ? args.list : []

        if receiver.could_be_nil? &&
           !(opts == SafeClass.safe_method_type_for(NilClass, signature) && receiver.cond == [receiver])
          # Do not add a condition if the method applies on nil
          cond += receiver.cond
          if (proc = opts[:pre_processor]) && !arg_list.detect {|a| !a.literal}
            # pre-processor on element that can be nil
            if proc.kind_of?(Proc)
              res = proc.call([receiver] + arg_list.map(&:literal))
              return t_if cond, res, res.opts
            end
          end
        elsif (proc = opts[:pre_processor]) && !arg_list.detect {|a| !a.literal}
          if proc.kind_of?(Proc)
            res = proc.call([receiver] + arg_list.map(&:literal))
          elsif receiver.literal
            res = receiver.literal.send(*([method] + arg_list.map(&:literal)))
          end
          if res
            if res.kind_of?(TypedString)
              # This can happen if we use native methods on TypedString (like gsub) that return a new
              # typedstring without calling initialize....
              if res.opts.nil?
                res.instance_variable_set(:@opts, :class => String, :literal => res)
              end
              return res
            else
              return t(res.inspect, :class => String, :literal => res)
            end
          end
        end

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

        if klass.respond_to?(:safe_method_type)
          type = klass.safe_method_type(signature, receiver)
        elsif klass.kind_of?(Array)
          unless type = SafeClass.safe_method_type_for(Array, signature)
            raise RubyLess::NoMethodError.new(receiver, "[#{klass}]", signature)
          end
        elsif type = SafeClass.safe_method_type_for(klass, signature)
        end

        raise RubyLess::NoMethodError.new(receiver, klass, signature) if !type || type[:class].kind_of?(Symbol) # we cannot send: no object.

        type[:class].kind_of?(Proc) ? type[:class].call(@helper, receiver ? receiver.klass : @helper, signature) : type
      end

      def get_lit_class(lit)
        unless lit_class = RubyLess::SafeClass.literal_class_for(lit.class)
          raise RubyLess::SyntaxError.new("#{klass} literal not supported by RubyLess.")
        end
        {:class => lit_class, :literal => lit}
      end

      def args_with_prepend(args, opts)
        if prepend_args = opts[:prepend_args]
          if prepend_args.kind_of?(Array)
            prepend_args = array_to_arguments(prepend_args)
          end
          if args
            prepend_args.append_argument(args)
            args = prepend_args
          else
            args = prepend_args
          end
        end

        if append_args = opts[:append_args]
          if append_args.kind_of?(Array)
            append_args = array_to_arguments(append_args)
          end
          if args
            args.append_argument(append_args)
          else
            args = append_args
          end
        end

        if append_hash = opts[:append_hash]
          last_arg = args.list.last
          unless last_arg.klass.kind_of?(Hash)
            last_arg = t "", String
            args.append_argument(last_arg)
          end
          append_hash.each do |key, value|
            last_arg.set_hash(key, value)
          end
          last_arg.rebuild_hash
          args.rebuild_arguments
        end
        args
      end

      def array_to_arguments(args)
        code = t('')
        args.each do |arg|
          code.append_argument(arg)
        end
        code
      end
  end
end
