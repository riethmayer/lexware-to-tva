# -*- coding: utf-8 -*-
class DeliveryAddress
  include PlaceAndZipcodeHelper
  attr_accessor :addition, :street, :zipcode, :place, :country
  def initialize(delivery_address)
    if delivery_address
      { :addition=  => 'Zusatz_Lieferanschrift',
        :street=    => 'Strasse_Lieferanschrift',
        :zipcode=   => 'PLZ_Lieferanschrift',
        :place=     => 'PLZ_Lieferanschrift',
        :country=   => 'Land_Lieferanschrift'
      }.each do |k,v|
        self.send k, Converter.xml_get(v, delivery_address)
      end
      extract_zipcode
      extract_place
      self.country = Country.new(self.country)
    end
  end

  def country_code
    raise "Country Code doesn't exist for #{self.country.name}" if self.country.name && !self.country.code
    self.country.code
  end
end
