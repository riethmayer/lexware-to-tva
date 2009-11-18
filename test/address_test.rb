# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class AddressTest < Test::Unit::TestCase
  include PlaceAndZipcodeHelper

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end

  def test_import_customer_address_from_xml
    xml = File.read(make_file('steuerfrei'))
    doc = Hpricot::XML(xml)
    adr = (doc/:Auftrag).first.at('Adresse')
    address = Address.new(adr)
    assert_match /Herr/, address.salutation
    assert_match /Bischof-Gross AG/, address.company
    assert_match /Markus Bischof/, address.fullname
    assert_match /Walenb.+?chelstrasse 21/, address.street
    assert_match /9001/, address.zipcode
    assert_match /St. Gallen/, address.place
    assert_equal 41, address.country.code
  end

  class Place
    include PlaceAndZipcodeHelper
    attr_accessor :place, :zipcode
    def initialize(str)
      self.place = str
      self.zipcode = str
    end
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

  def test_replace_country_with_code
    assert_equal 33, Country.new('Frankreich').code
    assert_equal 41, Country.new('Schweiz').code
    assert_equal 49, Country.new('Deutschland').code
    assert_equal 45, Country.new('Dänemark').code
    assert_equal 43, Country.new('Österreich').code
  end
end
