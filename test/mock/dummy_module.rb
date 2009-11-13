module DummyModule
  include RubyLess::SafeClass
  safe_method :maze => {:class => String, :method => 'mazette'}

  def mazette
    "Mazette !"
  end
end