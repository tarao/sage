require 'test/unit'
require File.join(File.dirname($0), 'lib')
require 'case'

class CaseTest < Test::Unit::TestCase
  def test_camel()
    assert_equal('CamelCase', 'camel_case'.to_camel)
    assert_equal('CamelCase', 'Camel_Case'.to_camel)
    assert_equal('CamelCase', 'camel_case'.to_camel)
  end

  def test_snake()
    assert_equal('snake_case', 'SnakeCase'.to_snake)
    assert_equal('snake_case', 'snakeCase'.to_snake)
  end
end
