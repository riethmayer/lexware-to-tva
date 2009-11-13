require File.join(File.dirname(__FILE__), 'test_helper')

class ConverterTest < Test::Unit::TestCase

  FILES    = File.join(File.dirname(__FILE__), "data")
  TESTFILE = File.join(FILES, "input", "all.xml")
  ITEMSFILE= File.join(FILES, "input", "111_items.xml")
  def setup
    @converter = Converter.new(FILES)
  end

  def test_import_orders_from_file
    # orders = @converter.import_orders_from(TESTFILE)
    # assert_equal 73, orders.length
  end

  def test_convert_sends_and_moves_files_from_input_dir
    # @converter.convert
  end

  def test_delivery_codes
    assert_equal 15, Converter.delivery_code('TNT Samstag')[:shipping_code]
  end

  def test_complete_items_count_is_111
    # @converter.output_dir = File.join(@converter.output_dir, "all_items")
    items = @converter.get_items_from(ITEMSFILE)
    assert_equal 111, items.length
  end

  def test_convert_all_items_to_output_dir_works
    @converter.output_dir = File.join(@converter.output_dir, "all_items")
    @converter.convert(only_items = true)
  end
end
