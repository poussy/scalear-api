class UpdateRoles < ActiveRecord::Migration[5.1]
  def change
  	ActiveRecord::Base.transaction do
      roles = {
        "User": 1,
        "Student": 2,
        "Professor": 3,
        "Teaching Assistant": 4,
        "Administrator": 5,
        "Preview": 6,
        "School Administrator": 9
      }

      roles.each do |name, id|
        Role.find(id).update_column(:name, name)
      end
    end
  end
end
