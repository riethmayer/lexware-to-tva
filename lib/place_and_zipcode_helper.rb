# -*- coding: utf-8 -*-
module PlaceAndZipcodeHelper

  def set_salutation
    unless /[a-z]/ =~ self.salutation.downcase
      self.salutation = "Frau/Herr/Firma"
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
