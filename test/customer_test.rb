# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class CustomerTest < Test::Unit::TestCase

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end

  def setup
    @converter = Converter.new(make_file('111_items'))
    @customers = @converter.get_customers
  end

  def test_all_customers_have_an_id
    @customers.each do |customer|
      assert customer.id
    end
  end
  #
  # default values
  #
  def test_default_currency_should_be_euro_for_all_customers
    @customers.each do |customer|
      assert_equal "<currencyCode>1</currencyCode>", customer.currency_code
    end
  end

  def test_default_language_should_be_german_for_all_customers
    @customers.each do |customer|
      assert_equal "<languageId>0</languageId>", customer.language_id
    end
  end

  def test_default_delivery_country_code_should_be_germany
    assert_equal 49, @customers[0].delivery_address_country_code
  end

  def test_default_invoice_country_code_should_be_germany
    c = @customers.first
    assert_equal 49, c.address.country.code
  end

  def test_customer_has_invoice_address
    c = @customers.first
    assert c.address
    assert c.address.zipcode
    assert_match /10999/, c.address.zipcode
    assert_match /Reichenbergerstra/, c.address.street
    assert_equal 49, c.address.country.code
  end

  def test_customer_to_xml_works
    c = @customers.first
    file = File.join(File.dirname(__FILE__), "data", "customer.xml")
    File.open(file, 'w') {|f| f.write(c.to_xml) }
  end

  def test_invoice_address_salutation
  end

end
