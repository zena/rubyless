require File.dirname(__FILE__) + '/active_record_mock'

class Dummy < RubyLess::ActiveRecordMock
  attr_reader :name
  include RubyLess::SafeClass
  
  safe_method  [:ancestor?, Dummy]  => Boolean
  safe_method  :parent              => {:class => 'Dummy', :special_option => 'foobar'},
               :children            => ['Dummy'],
               :project             => 'Dummy',
               :id                  => {:class => Number, :method => :zip},
               :name                => String
  safe_method  :defaults => {:nil => true},
               :spouse        => 'Dummy',
               :husband       => {:class => 'Dummy'}
             
  safe_attribute :age, :friend_id, :log_at, :format
  
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
  
  def husband
    nil
  end
  
  def zip
    10
  end
end