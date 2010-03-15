module RubyLess
  class NoMethodError < RubyLess::Error
    attr_reader :receiver, :klass, :signature

    def initialize(receiver, klass, signature)
      @receiver = receiver
      @klass = klass
      @signature = signature
    end

    def message
      "#{receiver_with_class}: #{error_message} '#{method_with_arguments}'."
    end

    def error_message
      if ivar?
        "unknown instance variable"
      else
        "unknown method"
      end
    end

    def receiver_with_class
      @receiver ? "#{@receiver} (#{@klass})" : "(#{@klass.class})"
    end

    def method_with_arguments
      method = @signature.first
      signature = @signature[1..-1]
      return method if ivar?
      if signature.size == 0
        arguments = ''
      else
        arguments = signature.map{|s| s.kind_of?(Class) ? s.to_s : s.inspect}.join(', ')
        if signature.size == 1 && (signature.first.kind_of?(Array) || signature.first.kind_of?(Hash))
          arguments = arguments[1..-2]
        end
      end
      "#{method}(#{arguments})"
    end

    def ivar?
      @signature.first =~ /\A@/
    end

  end
end