class Dummy
  attr_reader :name
  include RubyLess::SafeClass
  
  safe_method [:ancestor?, Dummy]  => RubyLess::Boolean
  safe_method :parent              => {:class => 'Dummy', :special_option => 'foobar'}
  safe_method :children            => ['Dummy']
  safe_method :project             => 'Dummy'
  safe_method :spouse              => {:class => 'Dummy', :nil => true}
  safe_method :id                  => {:class => RubyLess::Number, :method => :zip}
  safe_method :name                => String
  
  def initialize(name = 'dummy')
    @name = name
  end
  
  # This method returns pseudo-nil and does not need to be declared with :nil => true
  def project
    Dummy.new('project')
  end
  
  # This method can return nil and must be declared with :nil => true
  def spouse
    nil
  end
  
  def zip
    10
  end
end