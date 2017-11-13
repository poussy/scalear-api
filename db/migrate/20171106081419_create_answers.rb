class CreateAnswers < ActiveRecord::Migration[5.1]
  def change
    create_table :answers do |t|
      t.integer   :question_id
      t.text      :content
      t.boolean   :correct
      t.text      :explanation, :default => ""
      t.timestamps
    end
    add_index :answers, :question_id
  end
end
