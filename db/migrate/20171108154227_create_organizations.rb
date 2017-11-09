class CreateOrganizations < ActiveRecord::Migration[5.1]
	def up
		create_table :organizations do |t|
			t.string    :name
			t.string    :domain

			t.timestamps
		end

		add_index :organizations, :domain
	end

	def down
		drop_table :organizations
	end    
end