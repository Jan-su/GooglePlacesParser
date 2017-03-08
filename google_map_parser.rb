#!/bin/env ruby
# encoding: utf-8
require 'net/http'
require 'json'
require 'axlsx'
require "sinatra"
require "sinatra"


module GooglePlaces
	GOOGLE_API_KEY = '***'
	GOOGLE_API_KEY2 =  "***"
	class PlaceShow
		def initialize query
			@file_name ="axlsx.xlsx"
			@get_list_places_url = lambda  do |query, page_token| 
				has_next_page = '&hasNextPage=true&nextPage()=true&sensor=false&'
				main_url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query='
				url = main_url+query_for_url(query)+has_next_page+'key='+GOOGLE_API_KEY2+'&pagetoken='+page_token
				uri = URI(url)
			end		
			@get_place_url = lambda do  |query, page_token| 
				main_url = 'https://maps.googleapis.com/maps/api/place/details/json?placeid='
				url = main_url+query+'&key='+GOOGLE_API_KEY2
				uri = URI(url)
			end
			excel_doc query
		end


		def query_for_url query
			query.sub(' ', '+')
		end 

		def response_of query, url_method, page_token=nil
			uri = url_method.call query, page_token
			JSON.parse(Net::HTTP.get(uri))
		end

		def take_place_info place_hash
			result = place_hash['result'] 
			{
				'Источник'=>'',
				'Название' => result['name'],
				'Адрес'=>     result['formatted_address'],
				'Сайт'=>      result['website'], 
				'E-mail'=>    '',
				'Телефон'=>   result['formatted_phone_number']
			}
		end

		def parsed_places_id query
			place_ids = []
			next_page_token = ''
			loop do	
				places = response_of query, @get_list_places_url, next_page_token
				place_ids= place_ids + places["results"].map do |place_info| place_info['place_id'] end
				next_page_token = places.fetch("next_page_token", nil)
				break if not next_page_token
				sleep 2
			end
			place_ids
		end


		def list_of_place_info query
			list_of_place_info = []
			parsed_places_id(query).map do |place_id|
				response = response_of place_id, @get_place_url, nil
				list_of_place_info << take_place_info(response)
				sleep 2
			end
			list_of_place_info
		end

		def fill_with_parsed_info sheet, query
			row_hashes = list_of_place_info query
			sheet.add_row row_hashes[0].keys
			row_hashes.each do |row_hash|
				sheet.add_row row_hash.values
			end
		end

		def excel_doc query
			Axlsx::Package.new do |p|
				p.workbook do |wb|
					wb.add_worksheet do |sheet|
						fill_with_parsed_info sheet, query
					end
				end
				p.serialize @file_name
			end
		end

		def path_name
			begin
				File.absolute_path @file_name
			rescue
				nil
			end
		end
	end
end	


def excel_of query
	excel = GooglePlaces::PlaceShow.new query
end

get "/" do
	erb :google_map_parser
end

post "/send_to_server/" do
	content_type :json
	request.body.rewind  # in case someone already read it
	data = JSON.parse request.body.read
	a = excel_of data['query']
	('kek').to_json if a.path_name
end


