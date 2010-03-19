require 'test_helper'

class SignatureHashTest < Test::Unit::TestCase
  class SubString < String
  end

  context 'A SignatureHash' do
    subject do
      RubyLess::SignatureHash[
        [1, 2] => 'one, two',
        [:x, String, String] => 'x_string_string'
      ]
    end

    should 'find values by hashing' do
      assert_equal 'one, two', subject[[1,2]]
    end

    should 'return nil on invalid keys' do
      assert_nil subject['hop']
    end

    should 'find exact match' do
      assert_equal 'x_string_string', subject[[:x, String, String]]
    end

    should 'find subclass match' do
      assert_equal 'x_string_string', subject[[:x, SubString, String]]
    end

    should 'find subclass match at any position' do
      assert_equal 'x_string_string', subject[[:x, SubString, SubString]]
      assert_equal 'x_string_string', subject[[:x, String, SubString]]
    end

    should 'cache key on subclass match' do
      key = [:x, SubString, String]
      assert !subject.keys.include?(key)
      assert_equal 'x_string_string', subject[key]
      assert subject.keys.include?(key)
    end

  end
end