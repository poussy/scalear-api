class Forum::Post < ActiveResource::Base
	headers['Accept'] = "application/vnd.forum.v1" #v2
	self.site = Settings.scalear_forum + "/api/"

	attr_accessor :current_user

	def comments(scope = :all)
		comments = Forum::Comment.find(scope, :params => {:post_id => self.id, user_id:current_user.id})
		comments.each do |x|
			begin
				user =  User.find(x.user_id)
			rescue ActiveRecord::RecordNotFound
				user = User.new(:screen_name => "unknown", :email => "missing")
			end
			x.screen_name = user.screen_name
			x.email = user.email
		end
	end

	def comments_all(scope = :all)
		comments = Forum::Comment.find(scope, :params => {:post_id => self.id})
		comments.each do |x|
			begin
				user =  User.find(x.user_id)
			rescue ActiveRecord::RecordNotFound
				user = User.new(:screen_name => "unknown", :email => "missing")
			end
			x.screen_name = user.screen_name
			x.email = user.email
		end
	end

	def visible_comments(scope = :all)
		comments = Forum::Comment.find(scope, :params => {:post_id => self.id}).select{|v| v.hide == false}
	end

	def comment(id)
		comments(id)
	end

	def self.get_rounded_time(posts)
		return_hash={}
		questions={}
		posts.each do |p|
			parsed_time=p.time % 15 == 0 ? p.time : p.time - (p.time % 15)
			return_hash[parsed_time] = (return_hash[parsed_time]||0) + 1
			if questions[parsed_time]
				questions[parsed_time] << p
			else
				questions[parsed_time] = [p]
			end
		end
		return_hash.merge!(questions){|k,v1,v2| [v1,v2]}
		return return_hash
	end

	def self.get_rounded_time_module(array)
		return_hash={}
		questions={}
		Time.zone="UTC"
		array.each do |k,v|
			parsed_time=Time.zone.parse(Time.seconds_to_time(k[1])).floor(15.seconds).to_i #currently rounding to nearest minute. could change that. #to_i to use it in javascript
			return_hash[(parsed_time+k[0]).to_i] = (return_hash[(parsed_time+k[0]).to_i]||0) + 1
			if questions[(parsed_time+k[0]).to_i]
				questions[(parsed_time+k[0]).to_i] << v[1]
			else
				questions[(parsed_time+k[0]).to_i] = [v[1]]
			end
		end
		return_hash.merge!(questions){|k,v1,v2| [v1,v2]}
		return return_hash
	end
end