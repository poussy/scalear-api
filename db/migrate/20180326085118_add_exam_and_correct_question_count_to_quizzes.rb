class AddExamAndCorrectQuestionCountToQuizzes < ActiveRecord::Migration[5.1]
  def change
    add_column :quizzes, :exam, :boolean, :default => false
    add_column :quizzes, :correct_question_count, :integer, :default => 0
    add_column :quizzes, :show_explanation, :boolean, :default =>true
  end
end
