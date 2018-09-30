desc "Set all quizzes/surveys with 0 retries to 1"
task :reset_0_retries_quiz_to_1 do
 Quiz.where('quizzes.retries = 0').update_all('retries = 1')
end 