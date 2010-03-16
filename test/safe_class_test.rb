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
  end
end
