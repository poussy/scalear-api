class User < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable
          # :omniauthable
  include DeviseTokenAuth::Concerns::User

  attr_accessor :info_complete

  def info_complete
    return true
  end

  #only for testing 
  def roles
    return [{id:3}]
  end

  def intro_watched
    return true
  end

  def completion_wizard
    return {intro_watched: true}
  end

  # override devise function, to include methods with response
  def token_validation_response
    self.as_json(:methods => [:info_complete, :intro_watched])
  end
  
  
  
  

end
