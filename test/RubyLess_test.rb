require 'date'
require File.dirname(__FILE__) + '/test_helper.rb'

class StringDictionary
  include RubyLess::SafeClass
  safe_method [:[], Symbol] => {:class => String, :nil => true}
end

class SimpleHelper < Test::Unit::TestCase
  attr_reader :context
  yamltest :src_from_title => false
  include RubyLess::SafeClass
  safe_method :prev => {:class => Dummy, :method => 'previous'}
  safe_method :main => {:class => Dummy, :method => '@node'}
  safe_method :node => lambda {|h| {:class => h.context[:node_class], :method => h.context[:node]}}
  safe_method :now   => {:class => Time,  :method => "Time.now"}
  safe_method :birth => {:class => Time, :method => "Date.parse('2009-06-02 18:44')"}
  safe_method :dictionary => {:class => StringDictionary, :method => 'get_dict'}
  safe_method [:vowel_count, String]    => Number
  safe_method [:log_info, Dummy, String]    => String
  safe_method_for String, [:==, String] => Boolean
  safe_method_for String, [:to_s] => String
  safe_method_for Time, [:strftime, String] => String
  
  # Example to dynamically rewrite method calls during compilation
  def safe_method_type(signature)
    unless res = self.class.safe_method_type(signature)
      # try to execute method in the current var "var.method"
      if res = context[:node_class].safe_method_type(signature)
        res = res.call(self) if res.kind_of?(Proc)
        res[:method] = "#{context[:node]}.#{res[:method] || signature[0]}"
      end
    end
    res
  end
  
  def var1
    Dummy.new
  end
  
  def vowel_count(str)
    str.tr('^aeiouy', '').size
  end
  
  def log_info(obj, msg)
    "[#{obj.name}] #{msg}"
  end
  
  def yt_do_test(file, test, context = yt_get('context',file,test))
    @@test_strings[file][test].keys.each do |key|
      next if ['src', 'context'].include?(key)
      yt_assert yt_get(key,file,test), parse(key, file, test, context)
    end
  end
  
  def parse(key, file, test, opts)
    @context = {:node => 'var1', :node_class => Dummy}
    source = yt_get('src', file, test)
    case key
    when 'tem'
      source ? RubyLess.translate(source, self) : yt_get('tem', file, test)
    when 'res'
      eval(source ? RubyLess.translate(source, self) : yt_get('tem', file, test)).to_s
    when 'sxp'
      ParseTree.translate(source).inspect
    else
      "Unknown key '#{key}'. Should be 'tem' or 'res'."
    end
  rescue => err
    # puts "\n\n#{err.message}"
    # puts err.backtrace
    err.message
  end
  
  yt_make
end