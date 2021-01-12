require 'rails_helper'

describe Shift, type: :model do
  describe 'scopes' do
    describe '#assigned' do
      it 'returns only shifts with users' do
        create(:shift, user: nil)
        create(:shift)
        create(:shift)

        expect(Shift.assigned.count).to eq 2
      end
    end

    describe '#paid' do
      it 'filters on shifts Work and PaidAbsence' do
        work = create(:shift, :work)
        paid_absence = create(:shift, :paid_absence)
        create(:shift, :unpaid_absence)

        expect(Shift.paid.ids).to match_array([work.id, paid_absence.id])
      end
    end

    describe '#between' do
      it 'filters on shifts from a start date and an end date' do
        start_date = Date.parse('2020-02-01').to_datetime
        end_date = Date.parse('2020-02-10').to_datetime

        # WORKED SHIFTS
        work_1 = create(
          :shift, :work,
          starts_at: start_date + 1.day,
          ends_at: start_date + 1.day + 2.hours
        )
        work_2 = create(
          :shift, :work,
          starts_at: end_date - 1.hour,
          ends_at: end_date + 1.hour
        )
        # other works shifts
        create(
          :shift, :work,
          starts_at: start_date - 1.hour,
          ends_at: start_date + 1.hour
        )
        create(
          :shift, :work,
          starts_at: end_date + 1.hour,
          ends_at: end_date + 3.hours
        )

        # PAID ABSENCES
        paid_absence_1 = create(
          :shift, :paid_absence,
          starts_at: start_date + 1.day,
          ends_at: start_date + 1.day + 2.hours
        )
        paid_absence_2 = create(
          :shift, :paid_absence,
          starts_at: end_date - 1.hour,
          ends_at: end_date + 1.hour
        )
        # other works shifts
        create(
          :shift, :paid_absence,
          starts_at: start_date - 1.hours,
          ends_at: start_date + 1.hours
        )
        create(
          :shift, :paid_absence,
          starts_at: end_date + 1.hours,
          ends_at: end_date + 3.hours
        )

        # UNPAID ABSENCES
        unpaid_absence_1 = create(
          :shift, :unpaid_absence,
          starts_at: start_date + 1.day,
          ends_at: start_date + 1.day + 2.hours
        )
        unpaid_absence_2 = create(
          :shift, :unpaid_absence,
          starts_at: end_date - 1.hour,
          ends_at: end_date + 1.hour
        )
        # other works shifts
        create(
          :shift, :unpaid_absence,
          starts_at: start_date - 1.hour,
          ends_at: start_date + 1.hour
        )
        create(
          :shift, :unpaid_absence,
          starts_at: end_date + 1.hour,
          ends_at: end_date + 3.hours
        )

        expect(Shift.between(start_date.to_date, end_date.to_date).ids).to match_array(
          [
            work_1, work_2,
            paid_absence_1, paid_absence_2,
            unpaid_absence_1, unpaid_absence_2,
          ].map(&:id)
        )
      end
    end
  end

  describe 'validations' do
    describe 'shop association' do
      it 'does not validate shift if shop is missing' do
        shift = build(:shift, shop: nil)

        expect(shift).to be_invalid
        expect(shift.errors.details[:shop].pluck(:error)).to match_array [:blank]
      end

      it 'does not validate shift if shop does not exist' do
        shift = build(:shift, shop_id: 0)

        expect(shift).to be_invalid
        expect(shift.errors.details[:shop].pluck(:error)).to match_array [:blank]
      end
    end

    describe 'user association' do
      it 'validates shift even if user is missing' do
        shift = build(:shift, user: nil)

        expect(shift).to be_valid
      end
    end

    describe 'starts_at and ends_at' do
      it 'does not validate if there is no starts_at' do
        shift = build(
          :shift,
          starts_at: nil,
          ends_at: 1.hour.ago
        )

        expect(shift).to be_invalid
        expect(shift.errors.details[:starts_at].pluck(:error)).to match_array [:blank]
      end

      it 'does not validate if there is no ends_at' do
        shift = build(
          :shift,
          starts_at: 2.hours.ago,
          ends_at: nil
        )

        expect(shift).to be_invalid
        expect(shift.errors.details[:ends_at].pluck(:error)).to match_array [:blank]
      end

      it 'does not validate if ends_at is before starts_at' do
        shift = build(
          :shift,
          starts_at: 1.hours.ago,
          ends_at: 2.hours.ago
        )

        expect(shift).to be_invalid
        expect(shift.errors.details[:ends_at].pluck(:error)).to match_array [:before_starts_at]
      end
    end

    describe '#validate_less_than_maximum_duration' do
      let(:time) { DateTime.new(2020, 2, 15, 10, 50) }

      context 'work shift' do
        it 'validates less 10h duration' do
          shift = build(:shift, :work, starts_at: time, ends_at: time + 9.hours)

          expect(shift).to be_valid
        end

        it 'validates exactly 10h duration' do
          shift = build(:shift, :work, starts_at: time, ends_at: time + 10.hours)

          expect(shift).to be_valid
        end

        it 'does not validate over than 10h' do
          shift = build(:shift, :work, starts_at: time, ends_at: time + 10.hours + 1.second)

          expect(shift).to be_invalid
          expect(shift.errors.details[:base].pluck(:error)).to include(:too_long_shift)
        end
      end

      context 'paid absence' do
        it 'validates less than 12h duration' do
          shift = build(:shift, :paid_absence, starts_at: time, ends_at: time + 11.hours)

          expect(shift).to be_valid
        end

        it 'validates exactly 12h duration' do
          shift = build(:shift, :paid_absence, starts_at: time, ends_at: time + 12.hours)

          expect(shift).to be_valid
        end

        it 'does not validates over than 12h' do
          shift = build(:shift, :paid_absence, starts_at: time, ends_at: time + 12.hours + 1.second)

          expect(shift).to be_invalid
          expect(shift.errors.details[:base].pluck(:error)).to match_array [:too_long_shift]
        end
      end

      context 'unpaid absence' do
        it 'validates less than 24h duration' do
          shift = build(:shift, :unpaid_absence, starts_at: time, ends_at: time + 23.hours)

          expect(shift).to be_valid
        end

        it 'validates exactly 24h duration' do
          shift = build(:shift, :unpaid_absence, starts_at: time, ends_at: time + 24.hours)

          expect(shift).to be_valid
        end

        it 'does not validate over than 24h' do
          shift = build(:shift, :unpaid_absence, starts_at: time, ends_at: time + 24.hours + 1.second)

          expect(shift).to be_invalid
          expect(shift.errors.details[:base].pluck(:error)).to match_array [:too_long_shift]
        end
      end
    end

    describe '#validate_weeky_work_hours_limit' do
      let(:user) { create(:user) }
      let(:shop) { create(:shop) }

      it 'does not validate user weekly hours last over 35h/week' do
        user.shifts.work.create!(shop: shop, starts_at: '2019-02-04 10:00', ends_at: '2019-02-04 20:00')
        user.shifts.work.create!(shop: shop, starts_at: '2019-02-05 10:00', ends_at: '2019-02-05 20:00')
        user.shifts.work.create!(shop: shop, starts_at: '2019-02-06 10:00', ends_at: '2019-02-06 20:00')
        expect(user).to be_valid

        # On same week
        shift = user.shifts.work.build(
          shop: shop, starts_at: '2019-02-07 10:00', ends_at: '2019-02-07 20:00'
        )
        expect(shift).to be_invalid
        expect(shift.errors.details[:base].pluck(:error)).to eq [:max_weekly_duration_exceeded]

        # On another week
        shift = user.shifts.work.build(
          shop: shop, starts_at: '2019-02-20 10:00', ends_at: '2019-02-20 20:00'
        )
        expect(shift).to be_valid
      end
    end

    describe '#validate_daily_work_hours_limit' do
      let(:user) { create(:user) }
      let(:shop) { create(:shop) }

      context 'on the same shop' do
        it 'validates 10 hours on the same day' do
          user.shifts.work.create!(shop: shop, starts_at: '2019-02-04 10:00', ends_at: '2019-02-04 15:00')
          shift = user.shifts.work.build(
            shop: shop, starts_at: '2019-02-04 15:00', ends_at: '2019-02-04 20:00'
          )

          expect(shift).to be_valid
        end

        it 'does not validate more 10 hours on the same day' do
          user.shifts.work.create!(shop: shop, starts_at: '2019-02-04 10:00', ends_at: '2019-02-04 15:00')
          shift = user.shifts.work.build(
            shop: shop, starts_at: '2019-02-04 15:00', ends_at: '2019-02-04 20:01'
          )

          expect(shift).to be_invalid
          expect(shift.errors.details[:base].pluck(:error)).to eq [:max_daily_duration_exceeded]
        end
      end

      context 'on different shop' do
        it 'validates 10 hours on the same day' do
          other_shop = create(:shop)
          user.shifts.work.create!(shop: shop, starts_at: '2019-02-04 10:00', ends_at: '2019-02-04 15:00')
          shift = user.shifts.work.build(
            shop: other_shop, starts_at: '2019-02-04 15:00', ends_at: '2019-02-04 20:00'
          )

          expect(shift).to be_valid
        end

        it 'does not validate more 10 hours on the same day' do
          other_shop = create(:shop)
          user.shifts.work.create!(shop: shop, starts_at: '2019-02-04 10:00', ends_at: '2019-02-04 15:00')
          shift = user.shifts.work.build(
            shop: other_shop, starts_at: '2019-02-04 15:00', ends_at: '2019-02-04 20:01'
          )

          expect(shift).to be_invalid
          expect(shift.errors.details[:base].pluck(:error)).to eq [:max_daily_duration_exceeded]
        end
      end
    end
  end

  describe 'methods' do
    describe '#duration' do
      it 'computes shift duration' do
        shift = build(:shift, starts_at: '2020-01-15 10:00', ends_at: '2020-01-15 14:00')
        expect(shift.duration).to eq(4.hours)

        shift = build(:shift, starts_at: '2020-01-31 23:00', ends_at: '2020-02-01 01:00')
        expect(shift.duration).to eq(2.hours)
      end
    end

    describe '#duration_in_hours' do
      it 'computes shift duration in hours' do
        shift = build(:shift, starts_at: '2020-01-15 10:00', ends_at: '2020-01-15 14:00')
        expect(shift.duration_in_hours).to eq(4)

        shift = build(:shift, starts_at: '2020-01-31 23:00', ends_at: '2020-02-01 01:00')
        expect(shift.duration_in_hours).to eq(2)
      end
    end
  end
end
