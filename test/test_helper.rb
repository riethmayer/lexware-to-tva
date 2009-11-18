require 'rubygems'
require 'fileutils'
require 'test/unit'
base =  File.join(File.dirname(__FILE__),'..','lib')
require File.join(base, 'place_and_zipcode_helper')
require File.join(base, 'address')
require File.join(base, 'delivery_address')
require File.join(base, 'customer')
require File.join(base, 'converter')
require File.join(base, 'infoblock')
require File.join(base, 'item')
require File.join(base, 'order')
