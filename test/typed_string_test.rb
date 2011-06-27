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

    should 'maintain opts on dup' do
      other = subject.dup
      assert_equal TypedString, other.class
      assert_equal subject.opts, other.opts
      assert_equal subject.opts.object_id, other.opts.object_id
    end
  end
end
