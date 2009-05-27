class Dummy
  def self.safe_method?(signature)
    {
      [:ancestor?, Dummy] => Boolean,
    }[signature]
  end
end