class Dummy
  def self.safe_method?(signature)
    {
      [:ancestor?, Dummy] => RubyLess::Boolean,
    }[signature]
  end
end