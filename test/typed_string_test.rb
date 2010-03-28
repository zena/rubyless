require 'test_helper'

class TypedStringTest < Test::Unit::TestCase
  TypedString = RubyLess::TypedString

  context 'A typed string' do
    subject do
      TypedString.new('foo', Number)
    end

    should 'render with name' do
      assert_equal 'foo', subject.to_s
    end
    
    should 'return class of content on klass' do
      assert_equal Number, subject.klass
    end
  end
end
