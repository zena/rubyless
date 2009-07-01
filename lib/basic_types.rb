require 'safe_class'


class Boolean
end

class Number
end


RubyLess::SafeClass.safe_method_for( Number,
             [:==, Number] => Boolean, [:< , Number] => Boolean, [:> , Number] => Boolean, [:<=, Number] => Boolean, [:>=, Number] => Boolean,
             [:- , Number] => Number,  [:+ , Number] => Number,  [:* , Number] => Number,  [:/ , Number] => Number,
             [:% , Number] => Number,  [:"-@"]       => Number )
             