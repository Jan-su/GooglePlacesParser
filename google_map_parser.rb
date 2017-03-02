require 'net/http'
require 'json'
require 'google_places'





module GooglePlaces
	GOOGLE_API_KEY = 'AIzaSyBDpQ2kUxng4YXcSh1yPqH8MI4C4ipRNNM'
	GOOGLE_API_KEY2 =  'AIzaSyD9h_Zdt7XuEQ7vIm1TtOpPlAlFrC1Bc_s'
	class PlaceShow
		def self.query_for_url query
			query.sub(' ', '+')
		end 

		def self.response_of query, page_token
			has_next_page = '&hasNextPage=true&nextPage()=true&sensor=false&'
			main_url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query='
			url = main_url+query_for_url(query)+has_next_page+'key='+GOOGLE_API_KEY+'&pagetoken='+page_token
			uri = URI(url)
			response = Net::HTTP.get(uri)
		end

		def self.places_in_page query, next_page_token
			places = JSON.parse(response_of query, next_page_token)
		end

		def self.parsed_places query, next_page_token
			places = places_in_page(query, next_page_token)
			next_page_token = places.fetch("next_page_token", '')
			addresses =  places["results"].map do |place_info| place_info['formatted_address'] end
			if next_page_token then
				self.parsed_places(query, next_page_token) + addresses
			else
				[]+addresses
			end
		end
	end
end

GooglePlaces::PlaceShow.parsed_places("restaurant london", '').length