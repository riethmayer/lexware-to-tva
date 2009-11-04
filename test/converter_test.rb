require File.join(File.dirname(__FILE__), 'test_helper')

class ConverterTest < Test::Unit::TestCase

  TESTFILE = File.join(File.dirname(__FILE__), "data", "all.xml")

  def test_import_orders_from_file
    orders = Converter.import_orders_from(TESTFILE)
    assert_equal 112, orders.length
  end

  def test_convert_sends_and_moves_files_from_input_dir
    Converter.convert
  end



end
