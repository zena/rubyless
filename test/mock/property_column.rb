class MockPropertyColumn
  attr_reader :name, :default, :klass
  def initialize(name, default, type)
    case type
    when :string
      @klass = String
    when :number
      @klass = Number
    end
    @name = name
    @default = default
  end

  def number?
    @klass == Number
  end

  def text?
    @klass == String
  end
end