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