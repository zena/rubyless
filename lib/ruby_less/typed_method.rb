module RubyLess
  class TypedMethod
    attr_accessor :name, :args

    def initialize(*args)
      @name = args.shift
      @args = args
    end

    def add_argument(arg, klass_or_opts = nil)
      if klass_or_opts
        @args << TypedString.new(arg.to_s, klass_or_opts)
      elsif arg.kind_of?(TypedString)
        @arg << arg
      else
        raise Exception.new("Cannot add #{arg} to TypedMethod '#{name}' (no type and not a TypedString)")
      end
    end

    def set_hash(key, value, klass_or_opts)
      if last_is_hash?
        hash = @args.last
      else
        hash = TypedString.new
        @args << hash
      end

      hash.set_hash(key, TypedString.new(value, klass_or_opts))
    end

    def last_is_hash?
      @args.last.kind_of?(TypedString) && !@args.last.hash.empty?
    end

    def to_s
      if @args.empty?
        @name
      elsif last_is_hash?
        args = @args[0..-2].map(&:to_s)
        hash = @args.last
        hash.rebuild_hash
        hash = hash.to_s[1..-2]
        args += [hash]
        "#{@name}(#{args.join(', ')})"
      else
        "#{@name}(#{@args.join(', ')})"
      end
    end
  end
end