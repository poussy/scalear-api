class Forum::Comment < ActiveResource::Base
	headers['Accept'] = "application/vnd.forum.v1" #v2
	self.site = Settings.scalear_forum + "/api/posts/:post_id"

	def post
		Forum::Post.find(self.prefix_options[:post_id])
	end

	def post=(post)
		self.prefix_options[:post_id] = post.id
	end
end