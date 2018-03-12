class AddOrganizationIdToUsersRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :welcome_message, :text, :default => ""
    
    add_column :users_roles, :organization_id, :integer
    add_index  :users_roles, :organization_id

    ActiveRecord::Base.transaction do 
      domains_information = [{
        name:"Utrecht University",
        domain:"uu.nl"  
      }, {
        name:"Uppsala University",
        domain:"uu.se" 
      }]

      domains_information.each do |domain_information|  
        if !Organization.exists?(domain: domain_information[:domain]) 
          Organization.create(domain_information) 
        end 
      end 
      UsersRole.where(:role_id=>9).each do |user_role| 
        organization = Organization.find_by_domain(user_role.admin_school_domain) 
        user_role.update_attributes(admin_school_domain: 'all' , organization_id: organization.id ) 
      end 
    end 

  end
end
