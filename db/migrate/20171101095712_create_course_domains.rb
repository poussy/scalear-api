class CreateCourseDomains < ActiveRecord::Migration[5.1]
  def up
    create_table :course_domains do |t|
		t.integer  :course_id
		t.string  :domain
    	t.timestamps
    end
    add_index :course_domains, :course_id
  end
  def down
  	drop_table :course_domains
  end
end
