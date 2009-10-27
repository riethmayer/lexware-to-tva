module PlaceAndZipcodeHelper
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
  attr_accessor :salutation, :company, :fullname, :addition, :street, :zipcode, :place
  def initialize(address)
    { :salutation= => 'KundeAnrede',
      :company=    => 'KundeFirma',
      :fullname=   => 'KundeNameVorname',
      :addition=   => 'KundeZusatz',
      :street=     => 'KundeStrasse',
      :zipcode=    => 'KundePLZ_ORT',
      :place=      => 'KundePLZ_ORT'
      }.each do |k,v|
      self.send k, address.at(v).innerHTML
      end
    extract_zipcode
      extract_place
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
      self.send k, delivery_address.at(v).innerHTML
    end
    extract_zipcode
    extract_place
  end
end
