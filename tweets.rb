require 'sinatra'
require 'json'
require 'uri'
require 'base64'
require 'net/http'

module Settings
	def self.set_apikey a; @apikey = a end
	def self.get_apikey; @apikey end
	def self.set_apisecret a; @apisecret = a end
	def self.get_apisecret; @apisecret end
	def self.set_clientid c; @clientid = c end
	def self.get_clientid; @clientid end
end
load("configs.rb")

# twitter query
q = "%40theengineisred%20OR%23theengineisfive%20OR%23theengineis5"
apikey = Settings.get_apikey
apisecret = Settings.get_apisecret

get '/' do
	send_file File.expand_path('public/index.html', settings.public_folder)
end

get '/twee' do
	content_type = :json

	if request.query_string.length != 0
		q.concat "&since_id=" + request.query_string + "&result_type=recent"
	else
		q.concat "&max_id=449626277608423424"
	end

	t = Base64.strict_encode64(URI::encode(apikey) + ':' + URI::encode(apisecret))
	uri = URI("https://api.twitter.com/oauth2/token")
	req = Net::HTTP::Post.new(uri)
	req['Authorization'] = 'Basic ' + t
	req.content_type = 'application/x-www-form-urlencoded;charset=UTF-8'
	req.body = "grant_type=client_credentials"

	res = Net::HTTP.start(uri.hostname, uri.port,:use_ssl => uri.scheme == 'https') { |http|
	  http.request(req)
	}

	res = JSON.parse(res.body)
	if res['token_type'] == "bearer" 
		uri = URI("https://api.twitter.com/1.1/search/tweets.json?q=" + q)
		req = Net::HTTP::Get.new(uri)
		req['Authorization'] = 'Bearer ' + res['access_token']
		res = Net::HTTP.start(uri.hostname, uri.port,:use_ssl => uri.scheme == 'https') { |http|
		  http.request(req)
		}

		res.body
	end
end

get '/insta' do
	content_type = :json

	ru = "https://api.instagram.com/v1/users/40769184/media/recent/?client_id=" + Settings.get_clientid
	rt = "https://api.instagram.com/v1/tags/theengineisfive/media/recent/?client_id=" + Settings.get_clientid

	if request.query_string.length != 0
		#if request.query_string.to_i > "5e15".to_f
		if request.query_string.include? "_"
			# this is a query string from the user data
			r = ru.concat "&min_id='" + request.query_string + "'"
		else
			# tags query string
			r = rt.concat "&min_tag_id=" + request.query_string
		end
	else
		if Time.now.to_i % 2 == 0
			r = ru
		else
			r = rt
		end
	end

	uri = URI(r)
	req = Net::HTTP::Get.new(uri)
	res = Net::HTTP.start(uri.hostname,uri.port,:use_ssl => true) { |http|
		http.request(req)
	}
	res.body
end

