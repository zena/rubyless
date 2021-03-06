=begin rdoc
=end
require 'ruby_less/info'
require 'ruby_less/signature_hash'
require 'ruby_less/error'
require 'ruby_less/no_method_error'
require 'ruby_less/syntax_error'
require 'ruby_less/typed_string'
require 'ruby_less/typed_method'
require 'ruby_less/safe_class'
require 'ruby_less/processor'

module RubyLess
  def self.included(base)
    base.class_eval do
      include SafeClass
    end
  end

  # Return method type (options) if the given signature is a safe method for the class.
  def self.safe_method_type_for(klass, signature)
    SafeClass.safe_method_type_for(klass, signature)
  end

  def self.translate(receiver, string)
    RubyLessProcessor.translate(receiver, string)
  rescue Exception => err
    if err.kind_of?(RubyLess::Error)
      raise err
    else
      #puts err
      #puts err.backtrace
      raise RubyLess::Error.new("Error parsing \"#{string}\": #{err.message.strip}")
    end
  end

  def self.translate_string(receiver, string)
    if string =~ /\#\{/
      translate(receiver, "%Q{#{string}}")
    else
      TypedString.new(string.inspect, :class => String, :literal => string)
    end
  rescue Exception => err
    if err.kind_of?(RubyLess::Error)
      raise err
    else
      raise RubyLess::Error.new("Error parsing string \"#{string}\": #{err.message.strip}")
    end
  end
end

require 'ruby_less/basic_types'
