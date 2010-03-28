require 'ruby_less/safe_class'


class Boolean
end

class Number
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
