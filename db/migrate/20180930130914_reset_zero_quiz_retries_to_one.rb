class ResetZeroQuizRetriesToOne < ActiveRecord::Migration[5.1]
  def change
    Quiz.where('quizzes.retries = 0').update_all('retries = 1')
  end
end
