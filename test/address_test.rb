# -*- coding: utf-8 -*-
require File.dirname(__FILE__) +  '/test_helper'

class AddressTest < Test::Unit::TestCase
  include PlaceAndZipcodeHelper

  def test_import_customer_address_from_xml
    xml = File.read(File.join(File.dirname(__FILE__),'data','input','all.xml'))
    doc = Hpricot::XML(xml)
    adr = (doc/:Auftrag).first.at('Adresse')
    address = Address.new(adr)
    assert_match /Herr/, address.salutation
    assert_match /Lager von Testkunde AG/, address.company
    assert_match /Schumacher Herbert/, address.fullname
    assert_match /2. OG, Mitte/, address.addition
    assert_match /Schlesische Str. 4/, address.street
    assert_match /10997/, address.zipcode
    assert_match /Berlin/, address.place
    assert_equal 49, address.country.code
  end

  def test_import_customer_delivery_address_from_xml
    xml = File.read(File.join(File.dirname(__FILE__),'data', 'input','all.xml'))
    doc = Hpricot::XML(xml)
    adr = (doc/:Auftrag).first.at('Lieferadresse')
    delivery_address = DeliveryAddress.new(adr)
    assert_match /2. OG, Mitte/, delivery_address.addition
    assert_match /Schlesische Str. 14/, delivery_address.street
    assert_match /10999/,  delivery_address.zipcode
    assert_match /Kreuzberg/, delivery_address.place
    assert_equal 41, delivery_address.country.code
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
