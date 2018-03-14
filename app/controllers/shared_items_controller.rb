class SharedItemsController < ApplicationController
	
	load_and_authorize_resource
	
	# def index
	# end

	def create    
		shared_with= User.find_by_email(params[:shared_with])
		if !shared_with.nil?
			accept = shared_with.id == current_user.id
			@shared_item = SharedItem.new({:data => shared_item_params[:data], :shared_by_id => current_user.id, :shared_with_id  => shared_with.id, :accept => accept})
			if @shared_item.save
				render json: {shared_item:@shared_item, :notice => [I18n.t('controller_msg.data_successfully_shared',person: shared_with.email)]}, status: :created
			else
				render json: {errors: @shared_item.errors}, status: :unprocessable_entity
			end
		
		else
			render json: {errors: I18n.t("controller_msg.teacher_not_exist")}, :status => :unprocessable_entity
		end
  	end

	# def update
	# end

	def destroy
		share_item = SharedItem.find(params[:id])
		share_item.destroy
		render :json => {}
  	end

	# def show
	# end

	def show_shared
		shared_item=SharedItem.where(:shared_with_id => current_user.id, :accept => true)
		all_shared={}
		errors ={}
		shared_item.each do |shared|
			if !all_shared[shared.shared_by_id]
				all_shared[shared.shared_by_id] = []
			end
			teacher =User.find(shared.shared_by_id)
			item={:id =>shared.id, :teacher => {:email => teacher.email, :name =>teacher.full_name}, :modules =>[], :lectures => [], :quizzes =>[], :customlinks =>[], :created_at => shared.created_at}
			shared.data.each do |key, value|
				begin  
				if value && !value.empty?
					if key =="modules"
						value.each do |id|
							mod = Group.find(id)
							mod[:items] = mod.get_items
							mod[:description] = Course.find(mod[:course_id]).name
							item[:modules]<<mod
							# item[:modules][:course_id]<<
						end
					elsif key == "lectures"
						value.each do |id|
							item[:lectures]<<Lecture.find(id)
						end
					elsif key == "quizzes"
						value.each do |id|
							item[:quizzes]<<Quiz.find(id)
						end
					elsif key == "customlinks"
						value.each do |id|
							item[:customlinks]<<CustomLink.find(id)
						end
					end
				end
				rescue => error
				# errors << id
				end
			end
			all_shared[teacher.id] << item
		end
		courses = current_user.subjects_to_teach
		courses.each do |c|
			c[:modules] = c.groups.all
		end
		render :json => {:all_shared => all_shared, :courses => courses}
  	end

	def update_shared_data
		if(params[:data])
			s= SharedItem.find(params[:id])
			s.data ={:modules =>[], :lectures => [], :quizzes => [], :customlinks => []}
			params[:data].each do |key,value|
				if value
					s.data[key] = value.map{|v| v["id"]}
				end
			end

			if s.save
				render json: {}
			else
				render json: {:errors => [I18n.t("controller_msg.problem_updating_shared")]}, :status => 400
			end
		end		
	end

	def accept_shared
		
		if(@shared_item.shared_with_id == current_user.id)
			@shared_item.accept = true
			if @shared_item.save
				shared =current_user.shared_withs.where(:accept => false).size
				render json: {:notice => [I18n.t("controller_msg.accept_shared")], :shared_items => shared}
			else
				render json: {:errors => [I18n.t("controller_msg.cannot_accept")]}, :status => 400
			end
		else
			render :json => {:errors => I18n.t("controller_msg.wrong_credentials")}, :status => 404
		end
  	end

	def reject_shared
		s= SharedItem.find(params[:id])
		if(s.shared_with_id == current_user.id)
			s.destroy
			shared =current_user.shared_withs.where(:accept => false).size
			
			render json: {:notice => [I18n.t("controller_msg.reject_shared")], :shared_items => shared}
		else
			render :json => {:errors => I18n.t("controller_msg.wrong_credentials")}, :status => 404
		end
  	end
	private
		def shared_item_params
			params.require(:shared_item).permit(:data => {modules: [], lectures: [], quizzes: [], customlinks:[]})
		end
end