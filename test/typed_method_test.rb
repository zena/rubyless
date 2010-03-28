require 'test_helper'

class TypedMethodTest < Test::Unit::TestCase
  TypedMethod = RubyLess::TypedMethod

  context 'A method' do
    subject do
      TypedMethod.new('foo')
    end

    should 'render with name' do
      assert_equal 'foo', subject.to_s
    end

    should 'accept new arguments with add_argument' do
      assert_nothing_raised { subject.add_argument(1, Number) }
    end

    should 'accept new hash arguments' do
      subject.set_hash(:foo, 'bar', Dummy)
      assert_equal 'foo(:foo => bar)', subject.to_s
    end

    context 'with arguments' do
      subject do
        TypedMethod.new('foo', '1', '2')
      end

      should 'render with arguments' do
        assert_equal 'foo(1, 2)', subject.to_s
      end
    end

    context 'with a hash as last argument' do
      subject do
        m = TypedMethod.new('foo')
        m.add_argument('1', Number)
        m.set_hash(:foo, 'bar', Dummy)
        m
      end

      should 'use ruby last hash syntax' do
        assert_equal 'foo(1, :foo => bar)', subject.to_s
      end
    end
  end
end
