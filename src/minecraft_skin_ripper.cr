require "http"
require "json"
require "base64"

include HTTP

module MojangAPI
	def api_request(commands : Array(String))
		target_url="https://api.mojang.com"
		commands.each do |com|
			target_url+="/#{com}"
		end
		rsp= Client.get(target_url)
		return JSON.parse(rsp.body)
	end
	class User
		def initialize(@name : String,@id : String)
		end
		def initialize(username : String)
			@name=""
			@id=""
			begin
				json=api_request(["users","profiles","minecraft",username])
				@name=json["name"].to_s
				@id=json["id"].to_s
			rescue
				@name=username
				@id=""
			end
		end
		def id
			@id
		end
		def name
			@name
		end
		def skin_url
			begin
				rsp=Client.get("https://sessionserver.mojang.com/session/minecraft/profile/#{@id}")
				rsp_json=JSON.parse(rsp.body)
				skins=[] of String
				
				(0...rsp_json["properties"].size).each do |p_i|
					prop=rsp_json["properties"][p_i]
					if prop["name"].to_s=="textures"
						val=prop["value"].to_s
						skins_json=JSON.parse(Base64.decode_string(val))
						return skins_json["textures"]["SKIN"]["url"].to_s
					end
				end
			rescue
				return ""
			end
			return ""
		end
		def skin
			skinurl=skin_url
			if skinurl!=""
				return Client.get(skinurl).body.to_slice
			end
			return "".to_slice
		end
		def save_skin(filename : String=@name)
			skin_content=skin
			if skin_content.size>0
				File.open(filename,"wb") do |f|
					f.write(skin_content)
				end
			end
		end
	end
end

include MojangAPI

skindir="skins"
if !Dir.exists?(skindir)
	Dir.mkdir(skindir)
end
ARGV.each do |arg|
	if File.exists?(arg)
		#argument is file containing usernames to extract skins from.
		usernames=[] of String
		File.open(arg,"r") do |f|
			usernames=f.gets_to_end.split("\n")
		end
		usernames.each do |name|
			if name!=""
				user=User.new(name)
				user.save_skin("#{skindir}/#{user.name}")
			end
		end
	elsif ! arg.includes? "--"
		user=User.new(arg)
		user.save_skin("#{skindir}/#{user.name}")
	end
end

