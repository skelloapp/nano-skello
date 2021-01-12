require 'rails_helper'

describe User, type: :model do
  describe 'scopes' do
    describe '#users_active_on_shop_at' do
      let(:shop) { create(:shop) }
      let(:start_date) { Date.parse('2020-02-01') }
      let(:middle_date) { Date.parse('2020-02-15') }
      let(:end_date) { Date.parse('2020-02-28') }

      it 'returns only user who have a contract during the period' do
        # Schema to explaine all cases
        # S = Strart, E = End, u_x = user_x defined below
        #  range:          S|---------------|E
        #        |-u_1-| |-u_2-| |-u_3-| |-u_4-| |-u_5-|
        #    |--u_6--------------------------------------
        #                           |--u_7---------------
        #                                        |--u_8--

        # contracts starts and ends before range date
        user_1 = create(:user)
        create(:contract, shop: shop, user: user_1, starts_at: start_date - 2.months, ends_at: start_date - 1.month)

        # contracts starts before range and ends during range
        user_2 = create(:user)
        create(:contract, shop: shop, user: user_2, starts_at: start_date - 2.months, ends_at: middle_date)

        # contracts starts and ends during range
        user_3 = create(:user)
        create(:contract, shop: shop, user: user_3, starts_at: start_date + 2.days, ends_at: end_date - 2.days)

        # contracts starts during range and ends after range date
        user_4 = create(:user)
        create(:contract, shop: shop, user: user_4, starts_at: middle_date, ends_at: end_date + 2.days)

        # contracts starts and ends after range date
        user_5 = create(:user)
        create(:contract, shop: shop, user: user_5, starts_at: end_date + 1.months, ends_at: end_date + 2.months)

        # contracts starts before range and never ends
        user_6 = create(:user)
        create(:contract, shop: shop, user: user_6, starts_at: start_date - 2.months, ends_at: nil)

        # contracts starts during range and never ends
        user_7 = create(:user)
        create(:contract, shop: shop, user: user_7, starts_at: middle_date, ends_at: nil)

        # contracts starts after range and never ends
        user_8 = create(:user)
        create(:contract, shop: shop, user: user_8, starts_at: end_date + 1.month, ends_at: nil)

        expect(User.users_active_on_shop_at(shop, start_date, end_date)).to match_array(
          [user_2, user_3, user_4, user_6, user_7]
        )
      end

      it 'returns users with DESC contract strarts_at order' do
        user_1 = create(:user)
        create(:contract, shop: shop, user: user_1, starts_at: middle_date)
        user_2 = create(:user)
        create(:contract, shop: shop, user: user_2, starts_at: middle_date - 2.days)
        user_3 = create(:user)
        create(:contract, shop: shop, user: user_3, starts_at: middle_date + 2.days)
        user_4 = create(:user)
        create(:contract, shop: shop, user: user_4, starts_at: middle_date + 1.day)

        expect(User.users_active_on_shop_at(shop, start_date, end_date)).to eq(
          [user_3, user_4, user_1, user_2]
        )
      end
    end
  end

  describe 'validations' do
    describe 'email format' do
      it 'validates user with empty email' do
        user = build(:user, email: '')

        expect(user).to be_valid
      end

      it 'validates email format' do
        user = build(:user, email: 'test-email@domain.io')

        expect(user).to be_valid
      end

      it 'does not validate user if email is invalid' do
        user = build(:user, email: 'wrong@format.email@domain')

        expect(user).to be_invalid
        expect(user.errors.details.keys).to match_array([:email])
        expect(user.errors.details[:email].pluck(:error)).to include(:invalid)
      end
    end

    describe 'email uniqueness' do
      it 'does not validate user if email is already existing' do
        create(:user, email: 'already-existing@domain.com')

        user = build(:user, email: 'already-existing@domain.com')

        expect(user).to be_invalid
        expect(user.errors.details.keys).to match_array([:email])
        expect(user.errors.details[:email].pluck(:error)).to include(:taken)
      end

      it 'does not save a user if mail is already existing (case insensitive)' do
        create(:user, email: 'ALREADY-EXISTING@DOMAIN.COM')

        user = build(:user, email: 'already-existing@domain.com')

        expect(user).to be_invalid
        expect(user.errors.details.keys).to match_array([:email])
        expect(user.errors.details[:email].pluck(:error)).to include(:taken)
      end
    end
  end

  describe 'methods' do
    before do
      @user = create(:user)
    end

    describe '#monthly_wages' do
      it 'returns monthly salary with a single active contract' do
        # Mc Donalds
        mc_donalds = create(:shop, name: 'Mc Donalds')
        create(:contract, user: @user, shop: mc_donalds, starts_at: '2020-01-01', hourly_wage: 10)

        mc_donalds.shifts.work.create(user: @user, starts_at: '2020-01-02 09:00', ends_at: '2020-01-02 12:00')
        mc_donalds.shifts.work.create(user: @user, starts_at: '2020-01-02 13:00', ends_at: '2020-01-02 17:00')
        expect(@user.monthly_wages(mc_donalds, Date.parse('2020-01-01'))).to eq 70

        # Five Guys
        five_guys = create(:shop, name: 'Five Guys')
        create(:contract, user: @user, shop: five_guys, starts_at: '2020-01-01', hourly_wage: 12)
        expect(@user.monthly_wages(five_guys, Date.parse('2020-01-01'))).to eq 0

        five_guys.shifts.work.create(user: @user, starts_at: '2020-01-04 08:00', ends_at: '2020-01-04 10:00')
        five_guys.shifts.work.create(user: @user, starts_at: '2020-01-04 12:00', ends_at: '2020-01-04 18:00')
        five_guys.shifts.unpaid_absence.create(user: @user, starts_at: '2020-01-05 08:00', ends_at: '2020-01-05 10:00')
        five_guys.shifts.work.create(user: @user, starts_at: '2020-01-05 12:00', ends_at: '2020-01-05 17:00')
        five_guys.shifts.paid_absence.create(user: @user, starts_at: '2020-01-06 09:00', ends_at: '2020-01-06 12:00')
        five_guys.shifts.paid_absence.create(user: @user, starts_at: '2020-01-06 13:00', ends_at: '2020-01-06 17:00')

        expect(@user.monthly_wages(five_guys, Date.parse('2020-01-01'))).to eq 240
      end

      it 'returns monthly salary with multiple active contracts' do
        shop = create(:shop, name: 'Mc Donalds')
        create(:contract, user: @user, shop: shop, starts_at: '2020-01-01', ends_at: '2020-01-10', hourly_wage: 10)
        # User got a raise!
        create(:contract, user: @user, shop: shop, starts_at: '2020-01-10', ends_at: '2020-01-20', hourly_wage: 12.5)
        # User got another raise AND a permanent contract!
        create(:contract, user: @user, shop: shop, starts_at: '2020-01-20', ends_at: nil, hourly_wage: 14.7)

        # Shifts under first contract
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-02 10:00', ends_at: '2020-01-02 14:00:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-02 15:00', ends_at: '2020-01-02 19:00:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-03 10:00', ends_at: '2020-01-03 14:00:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-03 15:00', ends_at: '2020-01-03 19:00:00')
        expect(@user.monthly_wages(shop, Date.parse('2020-01-01'))).to eq 160

        # Shifts under second contract
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-10 10:00', ends_at: '2020-01-10 12:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-10 13:00', ends_at: '2020-01-10 17:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-11 10:00', ends_at: '2020-01-11 14:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-11 15:00', ends_at: '2020-01-11 18:00')
        expect(@user.monthly_wages(shop, Date.parse('2020-01-01'))).to eq 322.5

        # Shifts under third contract
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-22 10:00', ends_at: '2020-01-22 13:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-22 14:00', ends_at: '2020-01-22 18:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-23 10:00', ends_at: '2020-01-23 13:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-23 14:00', ends_at: '2020-01-23 18:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-01-25 10:00', ends_at: '2020-01-25 13:00')
        shop.shifts.unpaid_absence.create!(user: @user, starts_at: '2020-01-25 14:00', ends_at: '2020-01-25 18:00')
        expect(@user.monthly_wages(shop, Date.parse('2020-01-01'))).to eq 572.4

        # Shifts on February don't impact January salary
        shop.shifts.work.create!(user: @user, starts_at: '2020-02-02 10:00', ends_at: '2020-02-02 13:00')
        shop.shifts.work.create!(user: @user, starts_at: '2020-02-02 14:00', ends_at: '2020-02-02 18:00')
        expect(@user.monthly_wages(shop, Date.parse('2020-01-01'))).to eq 572.4
      end
    end
  end
end
