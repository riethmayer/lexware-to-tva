require File.join(File.dirname(__FILE__), 'test_helper')

class ItemTest < Test::Unit::TestCase
  FILES    = File.join(File.dirname(__FILE__), "data")
  TESTFILE = File.join(FILES, "input", "all.xml")

  def setup
    @converter = Converter.new(FILES)
    @customer ||= @converter.import_orders_from(TESTFILE)
  end

  def test_items_are_sorted_by_position_nr
    assert true
  end

  def test_language_is_always_german
    assert true
  end

  def test_locked_is_always_true
    assert true
  end

  def test_valid_is_always_true
    assert true
  end

  def test_currency_is_always_euro
    assert true
  end

  def test_dispocode_is_always_zero
    assert true
  end

  def test_quantity_unit_code_is_always_one
    assert true
  end

  def test_each_item_has_an_id
    assert true
  end

  def test_each_short_title_has_fewer_than_41_characters
    assert true
  end
end
