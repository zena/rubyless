require 'safe_class'

module RubyLess
  
  class Boolean
  end
  
  class Number
    include SafeClass
    safe_method( [:==, Number] => Boolean, [:< , Number] => Boolean, [:> , Number] => Boolean, [:<=, Number] => Boolean, [:>=, Number] => Boolean,
                 [:- , Number] => Number,  [:+ , Number] => Number,  [:* , Number] => Number,  [:/ , Number] => Number,
                 [:% , Number] => Number,  [:"-@"]       => Number )
  end
  
  
  class Missing
    [:==, :< , :> , :<=, :>=, :"?"].each do |sym|
      define_method(sym) do |arg|
        false
      end
    end
    
    def to_s
      ''
    end
    
    def nil?
      true
    end
    
    def method_missing(*meth)
      self
    end
  end
  
  Nil = Missing.new

  
end