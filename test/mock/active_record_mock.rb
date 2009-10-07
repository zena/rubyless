module RubyLess
  class ColumnMock
    def initialize(opts = {})
      @opts = opts
    end

    def default
      @opts[:default]
    end

    def type
      @opts[:type]
    end

    # Returns +true+ if the column is either of type string or text.
    def text?
      type == :string || type == :text
    end

    # Returns +true+ if the column is either of type integer, float or decimal.
    def number?
      type == :integer || type == :float || type == :decimal
    end

    # Returns the Ruby class that corresponds to the abstract data type.
    def klass
      case type
        when :integer       then Fixnum
        when :float         then Float
        when :decimal       then BigDecimal
        when :datetime      then Time
        when :date          then Date
        when :timestamp     then Time
        when :time          then Time
        when :text, :string then String
        when :binary        then String
        when :boolean       then Object
      end
    end

  end

  class ActiveRecordMock
    COLUMNS = {
      'format' => ColumnMock.new(:default => '%d.%m.%Y', :type   => :text),
      'age'    => ColumnMock.new(:default => 5,  :type => :float),
      'friend_id' => ColumnMock.new(:type => :integer),
      'log_at' => ColumnMock.new(:type => :datetime),
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