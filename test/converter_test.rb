require File.join(File.dirname(__FILE__), 'test_helper')

class ConverterTest < Test::Unit::TestCase

  FILES    = File.join(File.dirname(__FILE__), "data")
  TESTFILE = File.join(FILES, "input", "all.xml")

  def setup
    @converter = Converter.new(FILES)
  end

  def test_import_orders_from_file
    orders = @converter.import_orders_from(TESTFILE)
    assert_equal 112, orders.length
  end

  def test_convert_sends_and_moves_files_from_input_dir
    @converter.convert
  end


end
