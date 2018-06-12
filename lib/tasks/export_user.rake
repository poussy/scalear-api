task :export_user, [:email] => :environment do |t, args|

    user = User.find_by_email(args[:email].downcase)

    if !user
        puts "User with email #{args[:email].downcase} doesn't exist"

    else
        csv_files={}

        csv_files[:user_data]= CSV.generate do |csv_user_data|
        csv_files[:roles]= CSV.generate do |csv_roles|
        csv_files[:student_courses]= CSV.generate do |csv_student_courses|
        csv_files[:teacher_courses]= CSV.generate do |csv_teacher_courses|
        csv_files[:lecture_views] = CSV.generate do |csv_lecture_views|
        csv_files[:quiz_grades] = CSV.generate do |csv_quiz_grades|
        csv_files[:online_quiz_grades] = CSV.generate do |csv_online_quiz_grades|
        csv_files[:free_answers] = CSV.generate do |csv_free_answers|
        csv_files[:free_online_quiz_grades]= CSV.generate do |csv_free_online_quiz_grades|
        csv_files[:quiz_statuses]= CSV.generate do |csv_quiz_statuses|
        csv_files[:assignment_statuses]= CSV.generate do |csv_assignment_statuses|
        csv_files[:assignment_item_statuses]= CSV.generate do |csv_assignment_item_statuses|
        csv_files[:video_events]= CSV.generate do |csv_video_events|
        csv_files[:confuseds]= CSV.generate do |csv_confuseds|
        csv_files[:video_notes]= CSV.generate do |csv_video_notes|
        csv_files[:invitations]= CSV.generate do |csv_invitations|
        csv_files[:shared_items] = CSV.generate do |csv_shared_items|
        csv_files[:announcements]= CSV.generate do |csv_announcements|
        csv_files[:discussions]= CSV.generate do |csv_discussions|
                
                user_columns = ["id","provider","uid","remember_created_at","sign_in_count","current_sign_in_at","last_sign_in_at","current_sign_in_ip","last_sign_in_ip","failed_attempts","name","email","created_at","updated_at","last_name",
                        "screen_name","university","link","discussion_pref","completion_wizard","first_day","canvas_id","canvas_last_signin","saml","policy_agreement"]

                csv_user_data << user_columns
                csv_user_data << user.attributes.values_at(*user_columns)

                csv_roles << Role.column_names
                user.roles.each do |role|
                        csv_roles << role.attributes.values_at(*Role.column_names)
                end

                csv_student_courses << Course.column_names
                Enrollment.where(user_id:user.id).each do |enrollment|
                        csv_student_courses << Course.find(enrollment.course_id).attributes.values_at(*Course.column_names)
                end

                csv_teacher_courses << Course.column_names
                TeacherEnrollment.where(user_id:user.id).each do |enrollment|
                        csv_teacher_courses << Course.find(enrollment.course_id).attributes.values_at(*Course.column_names)
                end

                csv_lecture_views << LectureView.column_names
                user.lecture_views.each do |view|
                        csv_lecture_views << view.attributes.values_at(*LectureView.column_names)
                end

                csv_quiz_grades << QuizGrade.column_names
                user.quiz_grades.each do |grade|
                        csv_quiz_grades << grade.attributes.values_at(*QuizGrade.column_names)
                end

                csv_online_quiz_grades << OnlineQuizGrade.column_names
                user.online_quiz_grades.each do |grade|
                        csv_online_quiz_grades << grade.attributes.values_at(*OnlineQuizGrade.column_names)
                end

                csv_free_answers << FreeAnswer.column_names
                user.free_answers.each do |answer|
                        csv_free_answers << answer.attributes.values_at(*FreeAnswer.column_names)
                end

                csv_free_online_quiz_grades << FreeOnlineQuizGrade.column_names
                user.free_online_quiz_grades.each do |grade|
                        csv_free_online_quiz_grades << grade.attributes.values_at(*FreeOnlineQuizGrade.column_names)
                end

                csv_quiz_statuses << QuizStatus.column_names
                user.quiz_statuses.each do |status|
                        csv_quiz_statuses << status.attributes.values_at(*QuizStatus.column_names)
                end

                csv_assignment_statuses << AssignmentStatus.column_names
                user.assignment_statuses.each do |status|
                        csv_assignment_statuses << status.attributes.values_at(*AssignmentStatus.column_names)
                end

                csv_assignment_item_statuses << AssignmentItemStatus.column_names
                user.assignment_item_statuses.each do |status|
                        csv_assignment_item_statuses << status.attributes.values_at(*AssignmentItemStatus.column_names)
                end

                csv_video_events << VideoEvent.column_names
                user.video_events.each do |event|
                        csv_video_events << event.attributes.values_at(*VideoEvent.column_names)
                end

                csv_confuseds << Confused.column_names
                user.confuseds.each do |confused|
                        csv_confuseds << confused.attributes.values_at(*Confused.column_names)
                end

                csv_video_notes << VideoNote.column_names
                user.video_notes.each do |note|
                        csv_video_notes << note.attributes.values_at(*VideoNote.column_names)
                end

                csv_invitations << Invitation.column_names
                user.invitations.each do |invitation|
                        csv_invitations << invitation.attributes.values_at(*Invitation.column_names)
                end

                csv_announcements << Announcement.column_names
                user.announcements.each do |announcement|
                        csv_announcements << announcement.attributes.values_at(*Announcement.column_names)
                end

                csv_discussions << Forum::Post.get('column_names')
                Forum::Post.get("user_posts", {:user_id => user.id}).each do |post|
                        csv_discussions << post.values_at(*Forum::Post.get('column_names'))
                end

        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end
        end

        file_name = user.name+".zip"
        t = Tempfile.new(file_name)
        Zip::ZipOutputStream.open(t.path) do |z|
                csv_files.each do |key,value|
                        z.put_next_entry("#{key}.csv")
                        z.write(value)
                end
        end
        UserMailer.attachment_email(User.new(name:"ahmed",email:"okasha@novelari.com"), file_name, t.path, I18n.locale).deliver
        t.close
    end

end