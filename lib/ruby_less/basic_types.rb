require 'ruby_less/safe_class'


# Dummy classes
class Boolean
end

class Number
end

class StringDictionary
  include RubyLess
  safe_method ['[]', Symbol] => {:class => String, :nil => true}
  disable_safe_read # ?
end

RubyLess::SafeClass.safe_literal_class Fixnum => Number, Float => Number, Symbol => Symbol, Regexp => Regexp
RubyLess::SafeClass.safe_method_for( Number,
  [:==, Number] => Boolean, [:< , Number] => Boolean, [:> , Number] => Boolean,
  [:<=, Number] => Boolean, [:>=, Number] => Boolean, [:- , Number] => Number,
  [:+ , Number] => Number,  [:* , Number] => Number,  [:/ , Number] => Number,
  [:% , Number] => Number,  [:"-@"]       => Number
)

RubyLess::SafeClass.safe_method_for( String,
  [:==, String] => Boolean
)
