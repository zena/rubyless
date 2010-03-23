module DummyModule
  include RubyLess
  safe_method :maze => {:class => String, :method => 'mazette'}

  def mazette
    "Mazette !"
  end
end