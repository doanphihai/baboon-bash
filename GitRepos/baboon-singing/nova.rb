require 'net/http'
require 'json'
require 'nokogiri'

http          = Net::HTTP.new('novaplanet.com', 80)
request       = Net::HTTP::Get.new('/radionova/ontheair')
request["Host"]       = 'www.novaplanet.com'
request["Referer"]    = 'http://www.novaplanet.com/radionova/player'
request["User-Agent"] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:28.0) Gecko/20100101 Firefox/28.0'
request["Accept"]     = 'application/json, text/javascript'

response      = http.request(request)
response_json = JSON.parse(response.body)
nova_markup   = response_json['track']['markup']
noko_nova    = Nokogiri::HTML(nova_markup)

define_method(:get_info) do |css_class|
  noko_nova.css(css_class).text.strip
end

artist = get_info('.artist')
title = get_info('.title')

puts "    \"artist\": \"#{artist}\"\n    \"title\":\"#{title}\""
