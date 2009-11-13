require File.dirname(__FILE__) + '/active_record_mock'
require File.dirname(__FILE__) + '/dummy_module'

class Dummy < RubyLess::ActiveRecordMock
  include DummyModule
  include RubyLess::SafeClass

  attr_reader :name

  safe_method  [:ancestor?, Dummy]  => Boolean
  safe_method  :parent              => {:class => 'Dummy', :special_option => 'foobar'},
               :children            => ['Dummy'],
               :project             => 'Dummy',
               :image               => 'Dummy',
               :id                  => {:class => Number, :method => :zip},
               :name                => String,
               :foo                 => :bar,
               [:width, {:mode => String, :type => String, 'nice' => Boolean}]       => String
  safe_context :spouse  => 'Dummy',
               :husband => {:class => 'Dummy', :context => {:clever => 'no'}}

  safe_attribute :age, :friend_id, :log_at, :format

  def initialize(name = 'dummy')
    @name = name
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
end