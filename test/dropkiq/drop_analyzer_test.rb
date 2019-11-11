require "test_helper"

class DropkiqDropAnalyzerTest < Minitest::Test
  class PersonDrop < Liquid::Drop
    def initialize(person)
      @person = person
    end

    def name
      @person["name"]
    end

    def age
      @person["age"]
    end

    def active
      @person["active"]
    end

    def created_at
      @person["created_at"]
    end
  end

  class Person < ActiveRecord::Base
  end

  def setup
    setup_db

    @person = Person.create!({
      name: "John Doe",
      active: true,
      notes: "A banana is an edible fruit – botanically a berry – produced by several kinds of large herbaceous flowering plants in the genus Musa. In some countries, bananas used for cooking may be called \"plantains\", distinguishing them from dessert bananas. Wikipedia",
      age: 34
    })
    @person_drop = PersonDrop.new(@person)

    @analyzer = Dropkiq::DropAnalyzer.new(PersonDrop)
    @analyzer.analyze
  end

  def teardown
    teardown_db
  end

  def test_finds_correct_active_record_model
    assert_equal Person, @analyzer.active_record_class
  end

  def test_finds_correct_table_name
    assert_equal Person.table_name, @analyzer.table_name
  end

  def test_correctly_identifies_string_column
    @column = @analyzer.drop_methods.detect{|data| data[:name] == :name}
    assert_equal :string, @column[:type]
  end

  def test_correctly_identifies_integer_column
    @column = @analyzer.drop_methods.detect{|data| data[:name] == :age}
    assert_equal :integer, @column[:type]
  end

  def test_correctly_identifies_boolean_column
    @column = @analyzer.drop_methods.detect{|data| data[:name] == :active}
    assert_equal :boolean, @column[:type]
  end

  def test_correctly_identifies_datetime_column
    @column = @analyzer.drop_methods.detect{|data| data[:name] == :created_at}
    assert_equal :datetime, @column[:type]
  end

  def test_columns_not_implemented_in_drop_class_are_hidden
    @column = @analyzer.drop_methods.detect{|data| data[:name] == :updated_at}
    assert_nil @column
  end
end