# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string
#  firstname       :string           not null
#  lastname        :string           not null
#  password_digest :string           not null
#
class User < ActiveRecord::Base
  has_secure_password

  has_many :shifts
  has_many :contracts

  def monthly_wages(shop, date)
  end
end
