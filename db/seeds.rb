USERS_DB = [
  { firstname: 'Radioactive', lastname: 'Man' },
  { firstname: 'Kent', lastname: 'Brockman' },
  { firstname: 'Kirk', lastname: 'Van Houten' },
  { firstname: 'Timothy', lastname: 'Lovejoy' },
  { firstname: 'Moe', lastname: 'Szyslak' },
  { firstname: 'Lisa', lastname: 'Simpson' },
  { firstname: 'Homer', lastname: 'Simpson' },
  { firstname: 'Marge', lastname: 'Simpson' },
  { firstname: 'Bart', lastname: 'Simpson' },
  { firstname: 'Maggie', lastname: 'Simpson' },
  { firstname: 'Milhouse', lastname: 'Van Houten' },
  { firstname: 'Barney', lastname: 'Gumble' },
  { firstname: 'Cecil', lastname: 'Terwilliger' },
  { firstname: 'Abraham', lastname: 'Simpson' },
  { firstname: 'Troy', lastname: 'McClure' },
  { firstname: 'John', lastname: 'Frink' },
].freeze

SHOPS_DB = [
  { name: 'Springfield Retirement Castle' },
  { name: "Luigi's" },
  { name: "Moe's Tavern" },
  { name: 'Krusty Burger' },
  { name: 'The Springfield City Hall' },
  { name: 'The Frying Dutchman' },
].freeze

START_DATE = (Date.current - 1.months).freeze

def create_users_with_contracts!
  [].tap do |users|
    USERS_DB.each do |user_info|
      user = User.create(
        firstname: user_info[:firstname],
        lastname: user_info[:lastname],
        password: 'azertyuiop',
        password_confirmation: 'azertyuiop'
      )
      create_contracts!(user)
      users << user
    end
  end
end

def create_contracts!(user)
  shop_ids = @shops.pluck(:id)
  contract = Contract.create!(
    user: user,
    starts_at: DateTime.current.beginning_of_month,
    hourly_wage: 5,
    shop_id: shop_ids.sample
  )
  return unless user.id.even?

  Contract.create!(
    user: user,
    starts_at: DateTime.current.beginning_of_month,
    hourly_wage: 5,
    shop_id: (shop_ids - [contract.shop_id]).sample
  )
end

def create_two_months_planning!
  mondays = (START_DATE..(START_DATE + 1.months)).group_by(&:wday)[1]
  @users.each do |user|
    mondays.each { |monday| create_week_planning!(user, monday) }
  end
end

def create_week_planning!(user, monday)
  day_numbers = [0, 1, 2, 3, 4, 5, 6]
  work_day_numbers = day_numbers.sample(5)
  work_day_numbers.each do |day_number|
    Shift.work.create!(
      shop: user.contracts.last.shop,
      user: user,
      starts_at: monday + day_number.days + 8.hours,
      ends_at: monday + day_number.days + 9.hours
    )
  end

  (day_numbers - work_day_numbers).each do |day_number|
    Shift.create!(
      shop: user.contracts.last.shop,
      user: user,
      starts_at: monday + day_number.days + 8.hours,
      ends_at: monday + day_number.days + 9.hours,
      category: %w[paid_absence unpaid_absence].sample
    )
  end
end

ActiveRecord::Base.transaction do
  Shop.insert_all(SHOPS_DB)
  @shops = Shop.all

  @users = create_users_with_contracts!

  create_two_months_planning!
end

puts '👍'
