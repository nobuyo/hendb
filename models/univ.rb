class Univ < ActiveRecord::Base
  belongs_to :aspireUniv
  has_many :exams
end