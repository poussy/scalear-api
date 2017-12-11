class DiscussionsController < ApplicationController
	# rescue_from ActiveResource::BadRequest, with: :show_400_errors

	def create_post
		lecture_id = params[:post][:lecture_id]
		lecture = Lecture.find(lecture_id)

		params[:post] = params[:post].merge({:user_id => current_user.id  ,  :course_id => lecture.course_id,  :group_id => lecture.group_id} )
		
		post = Forum::Post.create(post_params)

		if post.valid?
			post.screen_name = current_user.screen_name
			post.email = current_user.email
			lecture  = Lecture.find(post.lecture_id)
			group = lecture.group
			course = lecture.course
			course.teacher_enrollments.where(:email_discussion => true).each do |teacher|
				UserMailer.delay.teacher_discussion_email(current_user,teacher.user,course,group,lecture,post, I18n.locale)
			end
			render json: { post: post }
		else
			render json: {errors: post.errors }, :status => 400
		end
	end

	# def get_posts #not used?
	# end

	def update_post
		post = Forum::Post.find(params[:post_id])
		post.content = params[:content]
		post.time = params[:time]
		post.edited = true
		if post.save
			render json: {:notice => [I18n.t("controller_msg.question_successfully_updated")]}
		else
			render json: {:errors => [I18n.t("controller_msg.could_not_update_question")]}, :status => 400
		end		
	end


	def delete_post
		post = Forum::Post.find(params[:post_id])
		lec = Lecture.find(post.lecture_id)
		if lec.course.user == current_user || post.user_id == current_user.id || current_user.roles.first.id == 1 || current_user.roles.first.id == 5
			Forum::Post.delete(params[:post_id])
			render json: {:notice => [I18n.t("controller_msg.successfully_deleted")]}
		else
			render json: {:errors => [I18n.t("controller_msg.could_not_delete_post")]}, :status => 400
		end		
	end

	def delete_comment
		c = Forum::Comment.find(params[:comment_id], :params => {:post_id => params[:post_id]})
		lec = Lecture.find(c.lecture_id)
		if lec.course.user == current_user || c.user_id == current_user.id || current_user.roles.first.id == 1 || current_user.roles.first.id == 5
			Forum::Comment.delete(params[:comment_id], :post_id => params[:post_id])
			render json: {:notice => [I18n.t("controller_msg.successfully_deleted")]}
		else
			render json: {:errors => [I18n.t("controller_msg.could_not_delete_comment")]}, :status => 400
		end
	end

	def create_comment
		params[:comment] = params[:comment].merge({:user_id => current_user.id})
		comment = Forum::Comment.create(comment_params)
		post = Forum::Post.find(params[:comment][:post_id])
		post_owner = User.find(post.user_id)
		comment_owner = current_user
		lecture  = Lecture.find(post.lecture_id)
		group = lecture.group
		course = lecture.course
		if comment.valid?
			comment.screen_name = current_user.screen_name
			comment.email = current_user.email
			if(post_owner != comment_owner)
				UserMailer.delay.discussion_reply_email(post_owner, comment_owner,course,group,lecture,post,comment, I18n.locale)#.deliver
			end
			render json: { comment: comment }
		else
			render json: { errors: comment.errors} , :status => 400
		end
	end

	# def get_comments
	# end

	def vote
		vote= Forum::PostVote.create(:post_vote => {user_id: current_user.id, post_id: params[:post_id], vote: params[:vote]})
		if vote.valid?
			render json: { vote: vote}
		else
			render json: { errors: vote.errors }, :status => 400
		end		
	end

	def flag
		flag= Forum::PostFlag.create(:post_flag => {user_id: current_user.id, post_id: params[:post_id]})
		if flag.errors.empty?
			render json: {flag: flag}
		else
			render json: {errors: flag.errors} , :status => 400
		end		
	end

	def vote_comment
		new_comment_vote= params[:comment_vote].merge({:user_id => current_user.id})
		vote= Forum::CommentVote.create(:comment_vote => new_comment_vote)
		if vote.valid?
			render json: { vote: vote }
		else
			render json: { errors: vote.errors } , :status => 400
		end
	end

	def flag_comment
		new_comment_flag= params[:comment_flag].merge({:user_id => current_user.id})
		flag = Forum::CommentFlag.create(:comment_flag => new_comment_flag)
		if flag.errors.empty?
		render json: { flag: flag }
		else
		render json: { errors: flag.errors }, :status => 400 
		end		
	end

	# def remove_all_flags
	# end

	# def remove_all_comment_flags
	# end

	# def hide_post
	# end

	# def hide_comment
	# end

	private
		def show_400_errors(exception)
			render :json => {:errors => ["API Exception"]}, :status => 400
		end

		def post_params
			params.require(:post).permit!
		end		

		def comment_params
			params.require(:comment).permit!
		end		
			
end