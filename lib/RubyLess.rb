$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'processor'

=begin rdoc
=end
module RubyLess
  VERSION = '0.3.3'

  def self.translate(string, helper)
    RubyLessProcessor.translate(string, helper)
  end
end
