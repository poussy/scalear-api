class User < ActiveRecord::Base

  before_create :add_default_user_role_to_user

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable
          # :omniauthable
  include DeviseTokenAuth::Concerns::User

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

  def has_role?(role)
    self.roles.pluck(:name).include?(role)      
  end

  private
      def add_default_user_role_to_user
        if !self.has_role?('User') 
          self.users_roles.build(role_id:1)
        end
        return true
      end
end
