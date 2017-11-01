class User < ActiveRecord::Base

  include DeviseTokenAuth::Concerns::User
  

  before_create :add_default_user_role_to_user

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable
          # :omniauthable

  attr_accessor :info_complete


  has_many :enrollments, :dependent => :destroy
  has_many :subjects_to_study, -> { distinct }, :through => :enrollments, :source => :course  # to get this call user.subjects


  has_many :teacher_enrollments, :dependent => :destroy
  has_many :subjects_to_teach, -> { distinct }, :through => :teacher_enrollments, :source => :course

  has_many :guest_enrollments, :dependent => :destroy
  has_many :guest_courses, -> { distinct }, :through => :guest_enrollments, :source => :course
  

  has_many :users_roles, :dependent => :destroy
  has_many :roles, -> { distinct }, :through => :users_roles

  # has_and_belongs_to_many :roles, -> {uniq} ,:join_table => :users_roles  

  has_many :announcements

  validates :name, :presence => true
  validates :last_name, :presence => true
  validates :screen_name, :presence => true, :uniqueness => true
  validates :university, :presence => true

  serialize :completion_wizard

  def has_role?(role)
    self.roles.pluck(:name).include?(role)      
  end

   # override devise function, to include methods with response
  def token_validation_response
    self.as_json(:methods => [:info_complete, :intro_watched])
  end


  def info_complete
    return self.valid?
  end

 
  def intro_watched
    if self.completion_wizard
      return self.completion_wizard[:intro_watched]
    else
      return false
    end
  end


  private
      def add_default_user_role_to_user
        if !self.has_role?('User') 
          self.users_roles.build(role_id:1)
        end
        return true
      end



end
