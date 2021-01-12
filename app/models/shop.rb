# == Schema Information
#
# Table name: shops
#
#  id   :integer          not null, primary key
#  name :string           not null
#
class Shop < ActiveRecord::Base
  has_many :contracts
  has_many :users, through: :contracts

  has_many :shifts

end
