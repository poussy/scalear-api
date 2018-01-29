class AddOrganizationIdToUsersRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :welcome_message, :text, :default => ""
    add_column :users_roles, :organization_id , :integer  
    add_index :users_roles, :organization_id 

    ActiveRecord::Base.transaction do 
      domains_informations = [ { name:"Utrecht University" , domain:"uu.nl"  } , { name:"Uppsala University" , domain:"uu.se" } ] 
      domains_informations.each do |domains_information|  
        if !Organization.exists?(domain: domains_information[:domain]) 
          Organization.create(:domain=> domains_information[:domain] , :name=> domains_information[:name]) 
        end 
      end 
      UsersRole.where(:role_id=>9).each do |users_role| 
        organization =  Organization.find_by_domain(users_role.admin_school_domain) 
        UsersRole.where(:user_id => users_role.user_id, :role_id => 9).update_all(admin_school_domain: 'all' , organization_id: organization.id ) 
      end 
    end 

  end
end
