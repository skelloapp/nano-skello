# == Schema Information
#
# Table name: shifts
#
#  id        :integer          not null, primary key
#  category  :integer          default("work"), not null
#  ends_at   :datetime         not null
#  starts_at :datetime         not null
#  shop_id   :integer          not null
#  user_id   :integer
#
# Foreign Keys
#
#  shop_id  (shop_id => shops.id)
#  user_id  (user_id => users.id)
#
class Shift < ActiveRecord::Base
  MAX_WEEKLY_WORK_DURATION = 35.hours
  MAX_DAILY_WORK_DURATION = 10.hours
  MAX_DAILY_PAID_ABSENCE_DURATION = 12.hours
  MAX_DAILY_UNPAID_ABSENCE_DURATION = 24.hours

  belongs_to :user, optional: true
  belongs_to :shop

  enum category: { work: 0, paid_absence: 1, unpaid_absence: 2 }

  validates :starts_at, presence: true
  validates :ends_at, presence: true

  # Scopes

  # Shifts associated to a user
  scope :assigned, -> {
  }
  # Shifts which are paid to their assigned user
  scope :paid, -> {
  }

  # Methods

  def duration
  end

  def duration_in_hours
  end
end
