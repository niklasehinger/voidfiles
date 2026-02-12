class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :prproj_uploads, dependent: :destroy

  ADMIN_EMAILS = %w[niklasehinger@googlemail.com].freeze

  def admin?
    ADMIN_EMAILS.include?(email)
  end
end
