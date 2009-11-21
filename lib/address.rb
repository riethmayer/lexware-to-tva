# -*- coding: utf-8 -*-
class Address
  include PlaceAndZipcodeHelper
  attr_accessor :salutation, :company, :fullname, :addition, :street, :zipcode, :place, :country
  def initialize(address)
    { :salutation= => 'KundeAnrede',
      :company=    => 'KundeFirma',
      :fullname=   => 'KundeNameVorname',
      :addition=   => 'KundeZusatz',
      :street=     => 'KundeStrasse',
      :zipcode=    => 'KundePLZ_ORT',
      :place=      => 'KundePLZ_ORT',
      :country=    => 'KundeLand'
      }.each do |k,v|
        self.send k, Converter.xml_get(v, address).strip
      end
    extract_zipcode
    extract_place
    set_salutation
    self.country = Country.new(self.country)
  end

  def self.differs?(a1,a2)
   ( a1.street != a2.street) || (a1.zipcode != a2.zipcode) || (a1.country != a2.country)
  end
end
