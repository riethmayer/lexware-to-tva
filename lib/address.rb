# -*- coding: utf-8 -*-
class Address
  include PlaceAndZipcodeHelper
  attr_accessor :salutation, :company, :fullname, :addition, :street, :zipcode, :place, :country

  def initialize(default = nil)
    self.import(default) if default
  end

  def import(address)
    { :salutation= => 'KundeAnrede',
      :company=    => 'KundeFirma',
      :fullname=   => 'KundeNameVorname',
      :addition=   => 'KundeZusatz',
      :street=     => 'KundeStrasse',
      :zipcode=    => 'KundePLZ_ORT',
      :place=      => 'KundePLZ_ORT',
      :country=    => 'KundeLand'
    }.each do |k,v|
      self.send k, Converter.xml_get(v, address)
    end
    extract_zipcode
    extract_place
    self.country = Country.new(self.country)
  end

  def has_country_code?
    self.country && self.country.code
  end

  def self.differs?(a1,a2)
    ( simple(a1.street)  != simple(a2.street)) ||
     (simple(a1.zipcode) != simple(a2.zipcode)) ||
     (simple(a1.country.name) != simple(a2.country.name))
  end

  # imagine a simple version of the string
  def self.simple str
    str.downcase.gsub(/^[a-z]/,"")
  end
  # to use factories
  def save!
  end
end
