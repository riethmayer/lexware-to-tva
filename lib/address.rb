# -*- coding: utf-8 -*-
module PlaceAndZipcodeHelper

  class Country
    attr_accessor :code, :name

    def initialize(name)
      self.name = name
      self.code = replace_country_with_code(name)
    end

    def eu?
      european_codes.include?(self.code)
    end

    def germany?
      self.code == 49
    end

    def other?
      !eu?
    end

    def european_codes
      [18, 31, 32, 33, 34, 35, 36, 39, 42, 43, 44, 45, 46, 47, 48, 49, 66]
    end

    def replace_country_with_code(name)
      countries = {
        'Luxemburg'                    => 18,
        'Niederlande'                  => 31,
        'Belgien'                      => 32,
        'Frankreich'                   => 33,
        'Spanien'                      => 34,
        'Finnland'                     => 35,
        'Ungarn'                       => 36,
        'Jugoslawien'                  => 38,
        'Italien'                      => 39,
        'Schweiz'                      => 41,
        'Tschechische Republik'        => 42,
        'Österreich'                   => 43,
        'Großbritannien'               => 44,
        'Dänemark'                     => 45,
        'Schweden'                     => 46,
        'Norwegen'                     => 47,
        'Polen'                        => 48,
        'Deutschland'                  => 49,
        'USA'                          => 50,
        'Peru'                         => 51,
        'Mexiko'                       => 52,
        'Kuba'                         => 53,
        'Argentinien'                  => 54,
        'Brasilien'                    => 55,
        'Chile'                        => 56,
        'Kolumbien'                    => 57,
        'Venezuela'                    => 58,
        'Bolivien'                     => 59,
        'Malaysia'                     => 60,
        'Australien'                   => 61,
        'Indonesien'                   => 62,
        'Phillippinen'                 => 63,
        'Griechenland'                 => 66,
        'Russland'                     => 73,
        'Japan'                        => 81,
        'Vietnam'                      => 84,
        'Hongkong'                     => 85,
        'China'                        => 86,
        'Indien'                       => 91,
        'Pakistan'                     => 92,
        'Jordanien'                    => 96,
        'Vereinigte Arabische Emirate' => 97
      }
      countries[name]
    end
  end

  def extract_zipcode
    if /\d+/ =~ self.zipcode
        self.zipcode = $&.strip  #matched zipcode
    else
      self.zipcode = nil # invalid zipcode
    end
  end

  def extract_place
    if /\D+$/ =~ self.place
      self.place = $&.strip   # matched place without zipcode
    else
      self.place = nil #invalid place
    end
  end
end

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
        self.send k, Converter.xml_get(v, address)
      end
    extract_zipcode
    extract_place
    self.country = Country.new(self.country)
  end
end

class DeliveryAddress
  include PlaceAndZipcodeHelper
  attr_accessor :addition, :street, :zipcode, :place, :country
  def initialize(delivery_address)
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
