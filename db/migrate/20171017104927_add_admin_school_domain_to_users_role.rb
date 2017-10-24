class AddAdminSchoolDomainToUsersRole < ActiveRecord::Migration[5.1]
	def up
		add_column :users_roles, :admin_school_domain, :string ,:default => ""
	end
	def down
		remove_column :users_roles, :admin_school_domain
	end
end
