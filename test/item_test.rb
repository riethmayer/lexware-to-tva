require File.join(File.dirname(__FILE__), 'test_helper')

class ItemTest < Test::Unit::TestCase

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end

  def setup
    @converter    ||= Converter.new(make_file('111_items'))
    @items        ||= @converter.items
  end

  def test_a_long_item_description_has_at_most_40_chars
    assert @converter.errors.empty?, "Converter had #{@converter.errors.size} Errors: \n #{@converter.errors.flatten.join("\n")}"
    item = @items.first
    assert item, "There is no first item in #{@items.size} Items <<#{@items}>>"
    assert item.title, "Item #{item.id} was expected to have a title"
    assert item.title.length <= 40, "Item #{item.id} was expected to have less or equal than 40 chars but had #{item.title.length}: #{item.title}"
  end

  def test_an_article_with_80_chars_title_has_a_description_2_field_with_40_chars
    item = @items.first
    assert item, "There is no first item in #{@items.size} Items <<#{@items}>>"
    item.title = "This is a very fancy title with a length of exactly 80 beautiful chars in total."
    assert "This is a very fancy title with a length" == item.truncated_title[0], "This is a very fancy title with a length != #{item.truncated_title[0]}"
    assert "of exactly 80 beautiful chars in total." == item.truncated_title[1], "of exactly 80 beautiful chars in total. != #{item.truncated_title[1]}"
    assert_match /description2/, item.to_xml
    assert_match /of exactly 80 beautiful chars/, item.to_xml
  end

  def test_an_article_with_160_chars_title_has_a_description_2_3_and_4field_with_40_chars
    item = @items.first
    assert item, "There is no first item in #{@items.size} Items <<#{@items}>>"
    item.title = "This is a very fancy title with length of exactly 160 beautiful chars in total, again it's a very fancy title with length of exactly 160 beautiful chars in tot."
    assert "This is a very fancy title with length" == item.truncated_title[0], "This is a very fancy title with a length != #{item.truncated_title[0]}"
    assert "of exactly 160 beautiful chars in total," == item.truncated_title[1], "of exactly 80 beautiful chars in total. != #{item.truncated_title[1]}"
    assert "again it's a very fancy title with"       == item.truncated_title[2], "again it's a very fancy title with != #{item.truncated_title[2]}"
    assert "length of exactly 160 beautiful chars in" == item.truncated_title[3], "length of exactly 160 beautiful chars in tot. != #{item.truncated_title[3]}"
    assert_match /description2/, item.to_xml
    assert_match /description3/, item.to_xml
    assert_match /description4/, item.to_xml
    assert_match /This is a very fancy title with length/, item.to_xml
    assert_match /of exactly 160 beautiful chars in total/, item.to_xml
    assert_match /again it\'s a very fancy title with/,item.to_xml
    assert_match /length of exactly 160 beautiful chars in/,item.to_xml
  end

   def test_file_with_invalid_positions
     @converter = Converter.new(make_file('Test'))
     assert @converter.convert
     assert @items     = @converter.items
   end



#   def test_items_are_sorted_by_position_nr
#     assert true
#   end

#   def test_language_is_always_german
#     assert true
#   end

#   def test_locked_is_always_true
#     assert true
#   end

#   def test_valid_is_always_true
#     assert true
#   end

#   def test_currency_is_always_euro
#     assert true
#   end

#   def test_dispocode_is_always_zero
#     assert true
#   end

#   def test_quantity_unit_code_is_always_one
#     assert true
#   end

#   def test_each_item_has_an_id
#     assert true
#   end

#   def test_each_short_title_has_fewer_than_41_characters
#     assert true
#   end
end
