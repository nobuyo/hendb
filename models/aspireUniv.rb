class AspireUniv < ActiveRecord::Base
  belongs_to :user
  has_one :univ
end