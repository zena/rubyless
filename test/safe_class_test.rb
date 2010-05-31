require 'test_helper'

class SafeClassTest < Test::Unit::TestCase
  class SubString < String
  end

  context 'A safe model' do
    subject do
      Dummy
    end

    should 'have an associated SignatureHash for safe methods' do
      assert_kind_of RubyLess::SignatureHash, Dummy.safe_methods
    end
  end # A safe model
  
  context 'An instance of a safe model' do
    subject do
      Dummy.new
    end
    
    context 'on safe_eval' do
      should 'evaluate RubyLess' do
        assert_equal 'Biscotte', subject.safe_eval("dog_name")
      end

      should 'raise NoMethodError on missing method' do
        assert_raise(RubyLess::NoMethodError) { subject.safe_eval("bad_method('Bp Oil Spill')") }
      end
    end # on safe_eval
    
    context 'on safe_eval_string' do
      should 'evaluate RubyLess as dstring' do
        assert_equal 'my Biscotte', subject.safe_eval_string('my #{dog_name}')
      end

      should 'raise NoMethodError on missing method' do
        assert_raise(RubyLess::NoMethodError) { subject.safe_eval_string("their \#{bad_method('Bp Oil Spill')}") }
      end
    end # on safe_eval
    
  end # An instance of a safe model
end
