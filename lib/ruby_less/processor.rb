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
      # Variable type definitions
      @variables  = {}
      # Method definitions
      @methods    = {}
      @cond_level = 0
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
      @cond_level += 1
      true_res  = process(exp.shift)
      false_res = process(exp.shift)
      @cond_level -= 1

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
      if (true_res && true_res.opts[:multiline]) ||
         (false_res && false_res.opts[:multiline])
        t "if #{cond}\n#{true_res || 'nil'}\nelse\n#{false_res || 'nil'}\nend", opts
      else
        t "(#{cond} ? #{true_res || 'nil'} : #{false_res || 'nil'})", opts
      end
    end

    def process_call(exp)
      unless receiver = process(exp.shift)
        # I think we can handle all cases without needing a define clause.
        # if exp.first == :define
        #   exp.shift
        #   return process_define(exp)
        # else
          receiver = @helper.kind_of?(TypedString) ? @helper : nil
        # end
      end

      method_call(receiver, exp)
    end

    def process_fcall(exp)
      method_call(@helper.kind_of?(TypedString) ? @helper : nil, exp)
    end
    
    def process_define(args, block_assign, block)
      types = process(args)
      meth = types.list.shift
      method_name = meth.literal
      unless method_name.kind_of?(Symbol)
        raise RubyLess::SyntaxError.new("Invalid method name. Should be a symbol, was #{meth.klass.inspect}.")
      end
      signature = [method_name.to_s]
      types.list.each do |arg|
        signature << Module::const_get(arg.opts[:method])
      end
      klass = signature.pop
      
      if defined_method?(signature)
        raise RubyLess::SyntaxError.new("Cannot redefine method #{signature.inspect}.")
      end
      i = 0
      if @variables[method_name]
        raise RubyLess::SyntaxError.new("Method name conflicts with variable '#{method_name}'.")
      end
      block_code = nil
      block_var = with_block_variables(block_assign, signature[1..-1]) do
        block_code = process(block)
      end
      define_method(signature, method_name.to_s, klass, "lambda do #{block_var}\n#{block_code}\nend")
    end
    
    def defined_method?(signature)
      !@methods[signature].nil?
    end
    
    def define_method(signature, method, klass, code)
      var_name = make_var_name(method)
      type = {
        :method => "#{var_name}.call",
        :class  => klass,
        :code   => "#{var_name} = #{code}"
      }
      @variables[method.to_sym] = true
      @methods[signature] = type
      t type[:code], :class => Proc
    end
    
    def with_block_variables(exp, sign, &block)
      keys = []
      if exp
        key = exp.shift
        if key == :masgn
          exp = exp.shift
          if exp.shift == :array
            while key = exp.shift
              key = key.last
              if !key.kind_of?(Symbol)
                raise RubyLess::SyntaxError.new("Block arguments should be symbols. Found #{key.inspect}.")
              end
              keys << key
            end
          end
        end
      end
      bak = {}
      @variables.each do |k,v|
        bak[k] = v
      end
      bvar = []
      keys.each_with_index do |k,i|
        if @variables[k]
          raise RubyLess::SyntaxError.new("Block argument shadows existing variable '#{k}'.")
        end
        name = make_var_name(k)
        bvar << name
        @variables[k] = t name, :class => sign[i]
      end
      block.call
      if bvar.size == 0
        ''
      else
        "|#{bvar.join(',')}|"
      end
    ensure
      @variables = bak
    end
    
    # TODO: Remove if we are sure it is not needed
    # :emails => String, :foo => Number
    def process_var_define(exp)
      # remove arglist
      types = process(exp.shift[1])
      types.hash.each do |var_name, var_type|
        var_name = var_name
        if type = @variables[var_name]
          raise RubyLess::SyntaxError.new("Type of #{var_name.inspect} already defined.")
        elsif var_type.klass == Class
          klass = Module::const_get(var_type.opts[:method])
          @variables[var_name] = t make_var_name(var_name), :class => klass, :nil => true
        elsif var_type.klass == [Class]  
          klass = Module::const_get(var_type.opts[:method])
          @variables[var_name] = t make_var_name(var_name), :class => [klass], :elem => klass, :nil => true
        else
          raise RubyLess::SyntaxError.new("Invalid type declaration #{var_type.klass} is not a Class.")
        end
      end
      t ''
    end
    
    def process_iter(exp)
      call  = exp.shift
      bargs = exp.shift
      block = exp.shift
      # remove :call
      call.shift
      # pass arguments
      method_call(call.shift, call, bargs, block)
    end
    
    def make_var_name(var_name)
      "_rl_#{var_name}"
    end
    
    def process_lvar(exp)
      var_name = exp.shift
      if type = @variables[var_name]
        type
      else
        raise RubyLess::Error.new("Unknown variable or method '#{var_name}'.")
      end
    end
    
    def process_lasgn(exp)
      var_name = exp.shift
      value = process(exp.shift)
      if type = @variables[var_name]
        if type == true
          raise RubyLess::SyntaxError.new("Variable name conflicts with method '#{var_name}'.")
        elsif value.klass != type.klass
          raise RubyLess::SyntaxError.new("Incompatible types. Setting '#{var_name}' to #{value.klass.inspect} instead of #{type.klass.inspect}")
        end
      else
        # First time we see this variable, set type
        if @cond_level > 0
          opts = value.opts.merge(:nil => true)
        else
          opts = value.opts
        end
        @variables[var_name] = t make_var_name(var_name), opts
      end
      t "#{make_var_name(var_name)} = #{value}", value.opts
    end
    
    def process_attrasgn(exp)
      process_call(exp)
    end
    
    def process_self(exp)
      method_call(nil, [:self])
    end
    
    def process_block(exp)
      code = []
      while !exp.empty?
        code << process(exp.shift)
      end
      if last = code.last
        t code.join("\n"), last.opts.merge(:multiline => true)
      else
        nil
      end
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

      def method_call(receiver, exp, block_assign = nil, block = nil)
        method = exp.shift.to_s
        arg_sexp = args = exp.shift # rescue nil
        
        if block && method == 'define'
          return process_define(arg_sexp, block_assign, block)
        end
        
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
        
        if !block && receiver && receiver.klass.kind_of?(Hash)
          # resolve now
          if signature.first == '[]' #&& klass = receiver.klass[args.literal]
            return receiver.hash[args.literal]
          else
            # safe_method_type on Hash... ?
            receiver = TypedString.new(receiver, Hash)
            opts = get_method(receiver, signature)
          end
        else  
          if block
            signature << Block
          end
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
          # TODO Implement with block
          method_call_with_receiver(receiver, args, opts, cond, signature)
        else
          if block
            block = " do\n#{process(block)}\nend"
          end
          method = opts[:method]
          args = args_with_prepend(args, opts)

          if (proc = opts[:pre_processor]) && !args.list.detect {|a| !a.literal}
            if proc.kind_of?(Proc)
              res = proc.call(*([receiver] + args.list.map(&:literal)))
            else
              res = @helper.send(proc, *args.list.map(&:literal))
            end

            return res.kind_of?(TypedString) ? res : t(res.inspect, :class => opts[:class], :literal => res)
          end

          if opts[:accept_nil]
            method_call_accepting_nil(method, args, opts, block)
          else
            args = "(#{args.raw})" if args
            t_if cond, "#{method}#{args}#{block}", opts
          end
        end
      end

      def method_call_accepting_nil(method, args, opts, block = nil)
        if args
          args = args.list.map do |arg|
            if !arg.could_be_nil? || arg.raw == arg.cond.to_s
              arg.raw
            else
              "(#{arg.cond} ? #{arg.raw} : nil)"
            end
          end.join(', ')

          t "#{method}(#{args})#{block}", opts
        else
          t "#{method}#{block}", opts
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
                res.instance_variable_set(:@opts, :class => opts[:class], :literal => res)
              end
              return res
            else
              return t(res.inspect, :class => opts[:class], :literal => res)
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
        if !receiver && type = @methods[signature]
          return type
        end
        
        klass = receiver ? receiver.klass : @helper

        if klass.respond_to?(:safe_method_type)
          type = klass.safe_method_type(signature, receiver)
        elsif klass.kind_of?(Array)
          unless type = SafeClass.safe_method_type_for(Array, signature)
            raise RubyLess::NoMethodError.new(receiver, "#{klass}", signature)
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
        if lit_class == Range
          {:class => lit_class, :literal => lit, :raw => "(#{lit.inspect})"}
        else
          {:class => lit_class, :literal => lit}
        end
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
