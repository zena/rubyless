require 'date'
require 'test_helper'

# Used to test sub-classes in optional arguments
class SubString < String
end

class RubyLessTest < Test::Unit::TestCase
  TEST_KEYS = %w{sxp tem res}
  attr_reader :context
  yamltest :src_from_title => false
  include RubyLess

  # Dynamic resolution of map
  def self.map_proc
    @@map_proc ||= Proc.new do |receiver, method|
      if elem = receiver.opts[:elem] || receiver.klass.first
        if type = RubyLess::safe_method_type_for(elem, [method.to_s])
          if type[:method] =~ /\A\w+\Z/
            res = "#{receiver.raw}.map(&#{type[:method].to_sym.inspect}).compact"
          else
            res = "#{receiver.raw}.map{|_map_obj| _map_obj.#{type[:method]}}.compact"
          end
          res = RubyLess::TypedString.new(res, :class => [type[:class]])
        else
          raise RubyLess::NoMethodError.new(receiver.raw, "[#{receiver.klass}]", ['map', method])
        end
      else
        # should never happen
        raise RubyLess::NoMethodError.new(receiver.raw, receiver.klass, ['map', method])
      end
    end
  end

  safe_method :prev => {:class => Dummy, :method => 'previous'}
  safe_method :main => {:class => Dummy, :method => '@node'}
  safe_method :self => Proc.new {|h, r, s| {:class => h.context[:node_class], :method => h.context[:node]}}
  safe_method :node => Proc.new {|h, r, s| {:class => h.context[:node_class], :method => h.context[:node]}}
  safe_method :now   => {:class => Time,  :method => "Time.now"}
  safe_method :birth => {:class => Time, :method => "Date.parse('2009-06-02 18:44')"}
  safe_method 'dictionary' => {:class => StringDictionary, :method => 'get_dict'}
  safe_method [:vowel_count, String]    => Number
  safe_method [:log_info, Dummy, String]    => String
  safe_method :foo  => :contextual_method, :bar => :contextual_method
  
  safe_method [:before, Symbol, Block] => NilClass

  safe_method_for String, [:==, String] => Boolean
  safe_method_for String, [:to_s] => String
  safe_method_for String, [:+, String] => String
  safe_method_for String, [:to_i] => {:class => Number, :pre_processor => true}
  safe_method_for String, [:split, String] => {:class => [String], :pre_processor => true}
  safe_method_for String, [:gsub, Regexp, String] => {:class => String, :pre_processor => Proc.new {|this, reg, str|
    # We have to test if 'this' is a literal
    if literal = this.literal
      this.gsub(reg, str)
    else
      # abort pre-processing
      nil
    end}}

  safe_method_for Array, [:map, Symbol] => {:method => 'nil', :class => nil, :pre_processor => self.map_proc}

  safe_method_for Array, [:join, String] => {:method => 'join', :class => String, :pre_processor => true}
  
  safe_method_for Range, :to_a => {:class => [Number], :pre_processor => true}

  safe_method_for Hash, :to_param => String

  safe_method_for String, :upcase => {:class => String, :pre_processor => true}

  safe_method_for Time, [:strftime, String] => String

  safe_method :now => {:method => 'Time.now', :class => Time}

  safe_method :@foo => {:class => Dummy, :method => "node"}
  safe_method :sub => SubDummy
  safe_method :str => SubString

  safe_method [:accept_nil, String] => {:class => String, :accept_nil => true}
  safe_method [:accept_nil, String, String] => {:class => String, :accept_nil => true}
  safe_method [:no_nil, String] => String

  safe_method [:no_op, String] => {:class => String, :method => ''}
  safe_method [:no_op, Number] => {:class => String, :method => 'transform'}

  safe_method [:hash_args, {'age' => Number, 'name' => String}] => String
  safe_method [:append_hash, Number, {'foo' => String}] => :make_append_hash

  safe_method [:concat, String, String] => {:class => String, :pre_processor => Proc.new{|this,a,b| a + b }}
  safe_method [:find, String] => {:class => NilClass, :method => 'nil', :pre_processor => :build_finder}

  # methods on nil
  safe_method_for Object, :blank? => Boolean
  
  # array context
  safe_method :list => [String]

  def safe_const_type(constant)
    if constant == 'Page'
      {:method => 'Page', :class => Class}
    elsif constant == 'String'
      {:method => 'String', :class => Class}
    elsif constant =~ /^D/
      {:method => constant[0..2].upcase.inspect, :class => String, :literal => constant}
    else
      nil
    end
  end

  # Example to dynamically rewrite method calls during compilation
  def safe_method_type(signature, receiver = nil)
    unless res = super
      if signature == ['prepend_one'] || signature == ['prepend_one', Number]
        res ={:class => Number, :prepend_args => RubyLess::TypedString.new('10', :class => Number), :method => 'add'}
      elsif signature == ['prepend_many'] || signature == ['prepend_many', Number]
        res ={:class => Number, :prepend_args => [RubyLess::TypedString.new('10', :class => Number), RubyLess::TypedString.new('20', :class => Number)], :method => 'add'}
      elsif signature == ['append_one'] || signature == ['append_one', Number]
        res ={:class => Number, :append_args => RubyLess::TypedString.new('10', :class => Number), :method => 'add'}
      elsif signature == ['append_many'] || signature == ['append_many', Number]
        res ={:class => Number, :append_args => [RubyLess::TypedString.new('10', :class => Number), RubyLess::TypedString.new('20', :class => Number)], :method => 'add'}
      elsif context && res = context[:node_class].safe_method_type(signature)
        # try to execute method in the current var "var.method"
        res = res[:class].call(self, signature) if res[:class].kind_of?(Proc)
        res = res.merge(:method => "#{context[:node]}.#{res[:method] || signature[0]}")
      end
    end
    res
  end

  def make_append_hash(signature = {})
    {:class => Number, :append_hash => {:xyz => RubyLess::TypedString.new('bar', :class => Dummy)}, :method => 'add'}
  end

  def build_finder(string)
    TypedString.new("secure(Node) { Node.find(#{string.inspect}) }", :class => Dummy )
  end

  def accept_nil(foo, bar=nil)
    [foo, bar].inspect
  end

  def no_nil(foo)
    foo
  end

  def get_dict
    {:foo => 'Foo'}
  end

  def contextual_method(signature)
    {:method => "contextual_#{signature[0]}", :class => String}
  end

  def node
    @node ||= Dummy.new
  end

  def sub
    SubDummy.new
  end
  
  def list
    %w{a b c}
  end

  def str
    "str"
  end

  def add(*args)
    args.inject(0) {|s,a| s+a}
  end

  def vowel_count(str)
    str.tr('^aeiouy', '').size
  end

  def log_info(obj, msg)
    "[#{obj.name}] #{msg}"
  end

  def test_safe_send
    assert_equal 10, Dummy.new.safe_send('id')
    assert_equal nil, Dummy.new.safe_send('rm')
  end

  def test_safe_method_type
    type = Dummy.safe_method_type(['husband'])
    type_should_be = {:class => Dummy, :method => 'husband', :nil => true, :context => {:clever => 'no'}}
    assert_equal type_should_be, type
  end

  def test_translate_with_typed_string
    typed_string = RubyLess::TypedString.new('marsupilami', :class => SubDummy, :message => 'Hello')
    assert_equal "marsupilami.says('Hello')", RubyLess.translate(typed_string, 'talk')
  end

  def test_literal_hash_type
    # Out of RubyLess::Processor, type is Hash, not {:foo => TypedString}.
    typed_string = RubyLess.translate(self, %q{{:foo => 'bar'}})
    assert_equal Hash, typed_string.klass
  end

  def test_should_not_alter_input_string
    orig_str = 'contact where id #{params[:foo]} in site'
    str = orig_str.dup
    RubyLess.translate(self, str)
  rescue RubyLess::Error => err
    assert_equal orig_str, str
  end

  def yt_do_test(file, test, context = yt_get('context',file,test))
    @node = Dummy.new
    hash = @@test_strings[file][test]
    TEST_KEYS.each do |key|
      if hash.has_key?(key)
        yt_assert yt_get(key, file, test), parse(key, file, test, context)
      end
    end
  end

  def parse(key, file, test, opts)
    @context = {:node => 'node', :node_class => Dummy}
    if source = yt_get('str', file, test)
      case key
      when 'tem'
        source ? RubyLess.translate_string(self, source) : yt_get('tem', file, test)
      when 'res'
        eval(source ? RubyLess.translate_string(self, source) : yt_get('tem', file, test)).to_s
      when 'sxp'
        RubyParser.new.parse(source).inspect
      else
        "Unknown key '#{key}'. Should be 'tem' or 'res'."
      end
    elsif source = yt_get('src', file, test)
      case key
      when 'tem'
        source ? RubyLess.translate(self, source) : yt_get('tem', file, test)
      when 'res'
        res = RubyLess.translate(self, source)
        eval(source ? RubyLess.translate(self, source) : yt_get('tem', file, test)).to_s
      when 'sxp'
        RubyParser.new.parse(source).inspect
      else
        "Unknown key '#{key}'. Should be 'tem' or 'res'."
      end
    end
  rescue RubyLess::Error => err
    # puts "\n\n#{err.message}"
    # puts err.backtrace
    err.message
  end

  def test_proc
    x = RubyLess.translate(self, 'main.proc_test')
    assert_equal self, x.opts[:h]
    assert_equal Dummy, x.opts[:r]
    assert_equal ['proc_test'], x.opts[:s]
  end

  yt_make
end