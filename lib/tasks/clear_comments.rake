namespace :clear_comments do

    task :all_comment => :environment do
        # users.each do |user|
        #     u = User.find_by_email(user[:email])
        #     u.subjects.destroy_all
        #
        #     u.courses.destroy_all
        #     u.subjects_to_teach.destroy_all
        # end
        # all_posts = []
        # all_user_ids = []
        # for user in users
        #     all_user_ids <<  user.id
        # end
        #
        # for

        user_comment_ids = Forum::Post.get("distinct_user_ids_of_all_comments")

        user_ids    = User.pluck(:id)


        id_deleted_user_account = user_comment_ids - user_ids  # ids of user accounts previousely deleted with their comments left


        id_deleted_user_account.in_groups_of(40,false){
            |group|
            d= Forum::Post.get("delete_comments_by_user_ids",{:ids_array=>group})

        }

    end
end
