class Forum::CommentFlag < ActiveResource::Base
	headers['Accept'] = "application/vnd.forum.v1" #v2
	self.site = Settings.scalear_forum + "/api"
end