require 'bcrypt'

class User < ActiveRecord::Base
  has_many :aspireUnivs

  validates :email, uniqueness: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }
  validates :email, presence: true
  validates :password_hash, confirmation: true
  validates :password_hash, presence: true
  validates :password_salt, presence: true

  def encrypt_password(password)
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  def auth(email, password)
    user = self.where(email: email)
    hashed = BCrypt::Engine.hash_secret(password, user.password_salt)
    (user && user.password_hash == hashed)? user : nil
  end
end