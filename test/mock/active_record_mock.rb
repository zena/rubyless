module RubyLess
  class ColumnMock
    def initialize(opts = {})
      @opts = opts
    end

    def default
      @opts[:default]
    end

    def text?
      @opts[:text]
    end

    def number?
      @opts[:number]
    end
  end

  class ActiveRecordMock
    COLUMNS = {
      'format' => ColumnMock.new(:default => '%d.%m.%Y', :text   => true),
      'age'    => ColumnMock.new(:default => 5,  :number => true),
      'friend_id' => ColumnMock.new(:number => true),
      'log_at' => ColumnMock.new,
    }
    def self.columns_hash
      COLUMNS
    end
    
    COLUMNS.each do |k, v|
      define_method(k) do
        v.default
      end
    end
  end
end