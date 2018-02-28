namespace :clear_comments do

    task :all_comment => :environment do


        user_comment_ids = Forum::Post.get("distinct_user_ids_of_all_comments")

        user_ids    = User.pluck(:id)


        id_deleted_user_account = user_comment_ids - user_ids  # ids of user accounts previousely deleted with their comments left


        id_deleted_user_account.in_groups_of(40,false){
            |group|
            d= Forum::Post.get("delete_comments_by_user_ids",{:ids_array=>group})

        }

    end
end
