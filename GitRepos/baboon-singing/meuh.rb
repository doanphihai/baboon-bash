require 'net/http'
require 'json'
require 'nokogiri'
# http://www.radiomeuh.com/player/pc8/playlist.php
http          = Net::HTTP.new('radiomeuh.com', 80)
request       = Net::HTTP::Get.new('/player/pc8/playlist.php')
request["Host"]       = 'www.radiomeuh.com'
request["Referer"]    = 'http://www.radiomeuh.com/player/pc8/view.htm'
request["User-Agent"] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:34.0) Gecko/20100101 Firefox/34.0'
request["Accept"]     = 'application/xml, text/xml, */*; q=0.01'

response      = http.request(request)
response_xml  = Nokogiri::XML(response.body)
current_track = response_xml.xpath("//track").select do |elem|
  elem["pos"] == "current"
end.first

define_method(:get_info) do |field_name|
  current_track.children.select do |elem|
    elem.name == field_name
  end.first.content
end
artist = get_info('artist')
title = get_info('titre')

puts "    \"artist\": \"#{artist}\"\n    \"title\": \"#{title}\""
