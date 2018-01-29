require 'open-uri'

namespace :db do
	desc "Import course from a collection of CSV zipped file"
	task :import_csv_course, [:url] => :environment do |t, args|
		# dev_null = Logger.new("/dev/null")
		# Rails.logger = dev_null
		# ActiveRecord::Base.logger = dev_null
	 	p args[:url]
		tmp_file = Tempfile.new('temp_file_prefix',  Rails.root.join('tmp'))
		tmp_file.binmode
		tmp_file.write(open(args[:url]).read)
		tmp_file.close
		needs_processing = ["answer", "explanation", "content"]
		puts tmp_file.path
		tables ={}
		Zip::ZipInputStream::open(tmp_file.path) do |io|
			while (entry = io.get_next_entry)
				p entry
				basename = File.basename(entry.name,File.extname(entry.name))
				model_name = basename.singularize.classify
				if model_name[-1,1] == "u"
					model_name+="s"
				end
				if model_name != "Discussion"
					model = model_name.constantize
					tables[model_name]  = []
					CSV.new(io.read, :headers => :first_row).each do |line|
						hashed_line = line.to_hash
						needs_processing.each do |v|
							if hashed_line[v] && hashed_line[v][0,1] == "["
								hashed_line[v] = hashed_line[v]
							end
						end
						tables[model_name] << hashed_line
					end
				end
			end
		end

		new_course = Course.new tables["Course"].first.slice(*Course.accessible_attributes)
		new_course.save(:validate => false)

		tables["Group"].each do |old_group|
			new_group = Group.new old_group.slice(*Group.accessible_attributes)
			new_group.course_id = new_course.id
			p new_group
			new_group.save(:validate => false)
			ActiveRecord::Base.transaction do
				tables["Lecture"].select{|l| l["group_id"] == old_group["id"]}.each do |old_lecture|
					new_lecture = Lecture.new old_lecture.slice(*Lecture.accessible_attributes)
					new_lecture.group_id = new_group.id
					new_lecture.course_id = new_course.id
					new_lecture.save(:validate => false)
					p new_lecture
					tables["Event"].select{|l| l["lecture_id"] == old_lecture["id"] && (l["quiz_id"] == nil || l["quiz_id"].blank? || l["quiz_id"]=="") }.each do |old_event|
						new_event = Event.new old_event.slice(*Event.accessible_attributes)
						new_event.course_id = new_course.id
						new_event.group_id = new_group.id
						new_event.lecture_id = new_lecture.id
						new_event.save(:validate => false)
					end

					tables["OnlineQuiz"].select{|q| q["lecture_id"] == old_lecture["id"]}.each do |old_online_quiz|
						new_online_quiz = OnlineQuiz.new old_online_quiz.slice(*OnlineQuiz.accessible_attributes)
						new_online_quiz.lecture_id = new_lecture.id
						new_online_quiz.group_id = new_group.id
						new_online_quiz.course_id = new_course.id
						new_online_quiz.save(:validate => false)

						tables["OnlineAnswer"].select{|a| a["online_quiz_id"] == old_online_quiz["id"]}.each do |old_online_answer|
							new_online_answer = OnlineAnswer.new old_online_answer.slice(*OnlineAnswer.accessible_attributes)
							new_online_answer.online_quiz_id = new_online_quiz.id
							new_online_answer.save(:validate => false)
						end
					end
				end

				tables["Quiz"].select{|quiz| quiz["group_id"] == old_group["id"]}.each do |old_quiz|
					new_quiz = Quiz.new old_quiz.slice(*Quiz.accessible_attributes)
					new_quiz.group_id = new_group.id
					new_quiz.course_id = new_course.id
					p new_quiz
					new_quiz.save(:validate => false)
					tables["Question"].select{|q| q["quiz_id"] == old_quiz["id"]}.each do |old_question|
						new_question = Question.new old_question.slice(*Question.accessible_attributes)
						new_question.quiz_id = new_quiz.id
						new_question.save(:validate => false)

						tables["Answer"].select{|a| a["question_id"] == old_question["id"]}.each do |old_answer|
							new_answer = Answer.new old_answer.slice(*Answer.accessible_attributes)
							new_answer.question_id = new_question.id
							new_answer.save(:validate => false)
						end
						tables["FreeAnswer"].select{|a| a["question_id"] == old_question["id"]}.each do |old_free_answer|
							new_free_answer = FreeAnswer.new old_free_answer.slice(*FreeAnswer.accessible_attributes)
							new_free_answer.question_id = new_question.id
							new_free_answer.quiz_id = new_quiz.id
							new_free_answer.save(:validate => false)
						end
					end
					tables["Event"].select{|l| l["quiz_id"] == old_quiz["id"] && (l["lecture_id"] == nil || l["lecture_id"].blank? || l["lecture_id"]=="") }.each do |old_event|
						new_event = Event.new old_event.slice(*Event.accessible_attributes)
						new_event.course_id = new_course.id
						new_event.group_id = new_group.id
						new_event.quiz_id = new_quiz.id
						new_event.save(:validate => false)
					end
				end
			end
			tables["CustomLink"].select{|l| l["group_id"] == old_group["id"] }.each do |old_custom_link|
				new_custom_link = CustomLink.new old_custom_link.slice(*CustomLink.accessible_attributes)
				new_custom_link.course_id = new_course.id
				new_custom_link.group_id = new_group.id
				new_custom_link.save(:validate => false)
			end
			tables["Event"].select{|l| l["group_id"] == old_group["id"] && (l["lecture_id"] == nil || l["lecture_id"].blank? ||  l["lecture_id"]=="" ) && (l["quiz_id"] == nil || l["quiz_id"].blank? || l["quiz_id"]=="") }.each do |old_event|
				new_event = Event.new old_event.slice(*Event.accessible_attributes)
				new_event.course_id = new_course.id
				new_event.group_id = new_group.id
				new_event.save(:validate => false)
			end
		end
		tables["CustomLink"].select{|l| l["group_id"] == nil || l["group_id"] == "" }.each do |old_custom_link|
			new_custom_link = CustomLink.new old_custom_link.slice(*CustomLink.accessible_attributes)
			new_custom_link.course_id = new_course.id
			new_custom_link.save(:validate => false)
		end

		new_course.user = User.find_by_email(tables["Teacher"].first["email"])
		tables["TeacherEnrollment"].each do |t|
			u = User.find_by_email(t["email"])
			if !u.nil?
				new_course.add_professor(u, false)
			else
				p "user not found #{t["email"]}"
			end
		end
		new_course.save(:validate => false)


		p new_course
		tmp_file.unlink
	end
end
