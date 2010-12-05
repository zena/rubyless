require File.dirname(__FILE__) + '/active_record_mock'
require File.dirname(__FILE__) + '/dummy_module'
require File.dirname(__FILE__) + '/property_column'

class Dummy < RubyLess::ActiveRecordMock
  include DummyModule
  include RubyLess

  attr_reader :name

  safe_method  [:ancestor?, Dummy]  => Boolean
  safe_method  :parent              => {:class => 'Dummy', :special_option => 'foobar'},
               :genitors            => ['Dummy'],
               :children            => {:class => ['Dummy'], :nil => true},
               :project             => 'Dummy',
               :image               => 'Dummy',
               :id                  => {:class => Number, :method => :zip},
               :name                => String,
               :foo                 => :bar,
               [:width, {:mode => String, :type => String, 'nice' => Boolean}] => String,
               [:kind_of?, Class]   => Boolean,
               [:kind_of?, String]  => {:method => 'is_like?', :class  => Boolean},
               # helper, receiver, signature
               :author => (Proc.new do |h, r, s| {:method => 'author', :class => Dummy} end)
               #:author => {:method => 'author', :class => Dummy}

               # just to test Proc.call
               safe_method :proc_test =>  Proc.new {|h, r, s| {:class => String, :method => '""', :h => h, :r => r, :s => s}}

  safe_context :spouse  => 'Dummy',
               :husband => {:class => 'Dummy', :context => {:clever => 'no'}}

  safe_attribute :age, :friend_id, :log_at, :format

  def initialize(name = 'dummy')
    @name = name
  end

  # Mock Property ================= [
  def self.schema; self; end
  def self.columns
    {
      'dog_name' => MockPropertyColumn.new('dog_name', nil, :string),
      'dog_age'  => MockPropertyColumn.new('dog_age', 0, :number),
    }
  end
  def prop
    {
      'dog_name' => 'Biscotte',
      'dog_age' => 6,
    }
  end
  # Mock Property ================= ]

  safe_property  :dog_name, :dog_age

  def self.safe_method_type(signature, receiver = nil)
    if signature == ['talk']
      {:class => String, :method => "says('#{receiver.opts[:message]}')"}
    else
      super
    end
  end

  def width(opts = {})
    return 'nice!' if opts['nice']
    "mode: #{(opts[:mode] || 'none')}, type: #{(opts[:type] || 'none')}"
  end

  # This method returns pseudo-nil and does not need to be declared with :nil => true
  def project
    Dummy.new('project')
  end

  def image
    Dummy.new('image')
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

  def author
    Dummy.new('bob')
  end
end

class SubDummy < Dummy
end
