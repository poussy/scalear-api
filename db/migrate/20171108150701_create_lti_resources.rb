class CreateLtiResources < ActiveRecord::Migration[5.1]
	def up
		create_table :lti_resources do |t|
			t.string :resource_context_id
			t.string :sl_type_name_type_id
			t.timestamps
		end
	end

	def down
		drop_table :lti_resources
	end
end
