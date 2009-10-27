require File.dirname(__FILE__) +  '/test_helper'

class AddressTest < Test::Unit::TestCased

  def test_import_customer_address_from_xml
    xml = File.read(File.join(File.dirname(__FILE__),'data', 'test.xml'))
    doc = Hpricot::XML(xml)
    adr = (doc/:Auftrag).first.at('Adresse')
    address = Address.new(adr)
    assert_equal 'Herr', address.salutation
    assert_equal 'optimiere.com', address.company
    assert_equal 'Jan Riethmayer', address.fullname
    assert_equal '2. OG, Mitte', address.addition
    assert_equal 'Mindener Str. 20', address.street
    assert_equal '10589', address.zipcode
    assert_equal 'Berlin', address.placed
  end

  def test_import_customer_delivery_address_from_xml
    xml = File.read(File.join(File.dirname(__FILE__),'data', 'test.xml'))
    doc = Hpricot::XML(xml)
    adr = (doc/:Auftrag).first.at('Lieferadresse')
    delivery_address = DeliveryAddress.new(adr)
    assert_equal '2. OG, Mitte', delivery_address.addition
    assert_equal 'Mindener Str. 20', delivery_address.street
    assert_equal '10589',  delivery_address.zipcode
    assert_equal 'Berlin', delivery_address.place
    assert_equal 'Deutschland', delivery_address.country
  end

  def test_extract_zipcode_works_for_regular_zipcodes
    p = Place.new("10997 Berlin")
    assert_equal "10997", p.extract_zipcode
    assert_equal "Berlin", p.extract_place
  end
  def test_zipcode_is_empty_if_missing
    p = Place.new("Berlin")
    assert_equal "Berlin", p.extract_place
    assert_equal nil, p.extract_zipcode
  end
  def test_place_is_empty_if_missing
    p = Place.new("10997")
    assert_equal "10997", p.extract_zipcode
    assert_equal nil, p.extract_place
  end
  def test_extract_zipcode_works_for_large_districts_with_trailing_spaces
    p = Place.new("10997 Berlin-Charlottenburg   ")
    assert_equal "10997", p.extract_zipcode
    assert_equal "Berlin-Charlottenburg", p.extract_place
  end
  def test_extract_zipcode_works_for_regular_zipcodes
    p = Place.new("10997 Berlin Charlottenburg")
    assert_equal "10997", p.extract_zipcode
    assert_equal "Berlin Charlottenburg", p.extract_place
  end

  class Place
    include PlaceAndZipcodeHelper
    attr_accessor :place, :zipcode
    def initialize(str)
      self.place = str
      self.zipcode = str
    end
  end
end
