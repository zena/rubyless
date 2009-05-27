require File.dirname(__FILE__) + '/test_helper.rb'

class SimpleHelper < Test::Unit::TestCase
  yamltest
  
  def context
    {:node => 'var1', :node_class => Dummy}
  end

  def variable(name)
    { 'prev' => ['previous', Dummy],
      'main' => ['@node', Dummy],
      'node' => [context[:node], context[:node_class]],
      'id'   => ["#{context[:node]}.zip", RubyLess::Number],
      'now'  => ["Time.now", Time],
      'name' => ["#{context[:node]}.name", String],
    }[name]
  end

  def safe_method?(signature)
    {
      [:strftime, Time, String] => String,
    }[signature]
  end

  def any_safe_method?(signature)
    {
      [:to_i] => RubyLess::Number,
      [:to_s] => String,
    }[signature]
  end

  def yt_parse(key, source, opts)
    RubyLess.translate(source, self)
  rescue => err
    err.message
  end
  
  yt_make
end