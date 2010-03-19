=begin rdoc
=end
require 'ruby_less/info'
require 'ruby_less/basic_types'
require 'ruby_less/signature_hash'
require 'ruby_less/error'
require 'ruby_less/no_method_error'
require 'ruby_less/syntax_error'
require 'ruby_less/typed_string'
require 'ruby_less/safe_class'
require 'ruby_less/processor'

module RubyLess
  def self.translate(string, helper)
    RubyLessProcessor.translate(string, helper)
  end

  def self.translate_string(string, helper)
    if string =~ /\#\{/
      ::RubyLess.translate("%Q{#{string}}", helper)
    else
      string.inspect
    end
  rescue => err
    raise ::RubyLess::Error.new("Error parsing string \"#{string}\": #{err.message.strip}")
  end
end
