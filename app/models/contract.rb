# == Schema Information
#
# Table name: contracts
#
#  id          :integer          not null, primary key
#  ends_at     :datetime
#  hourly_wage :float            not null
#  starts_at   :datetime         not null
#  shop_id     :integer          not null
#  user_id     :integer          not null
#
# Foreign Keys
#
#  shop_id  (shop_id => shops.id)
#  user_id  (user_id => users.id)
#
class Contract < ActiveRecord::Base
  belongs_to :user
  belongs_to :shop

  before_save :starts_at_to_midnight

  scope :active_at, -> (period_start, period_end) {
    where('? < ends_at OR ? > starts_at', period_start, period_end)
  }

  private

  def starts_at_to_midnight
  end
end
