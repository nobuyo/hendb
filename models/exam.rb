class Exam < ActiveRecord::Base
  belongs_to :univ
  has_many :subject
end