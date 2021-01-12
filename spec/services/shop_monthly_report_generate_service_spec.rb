require 'rails_helper'

RSpec.describe ShopMonthlyReportGenerateService, type: :service do
  describe 'Shop monthly report generate service' do
    before do
      @shop = create(:shop)
      @date = DateTime.parse('2020-02-15')
    end

    describe 'failure' do
      it 'fails if shop_id is wrong' do
        expect do
          ShopMonthlyReportGenerateService.new(
            Shop.last.id + 1,
            @date,
            @file_name
          )
        end.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it 'fails if date is nil' do
        generator = ShopMonthlyReportGenerateService.new(
          @shop.id,
          nil,
          @file_name
        )

        expect { generator.run }.to raise_error(ArgumentError, 'ERROR: Date is missing')
      end

      it 'fails if file_name is missing' do
        generator = ShopMonthlyReportGenerateService.new(
          @shop.id,
          @date,
          nil
        )

        expect { generator.run }.to raise_error(ArgumentError, 'ERROR: File name missing')
      end
    end

    describe 'success' do
      before do
        # 2 users excluded from report because on other shop
        create_list(:contract, 2, starts_at: @date - 1.month, ends_at: nil)

        # 2 users excluded from report because contracts end too soon
        create_list(:contract, 2, shop: @shop, starts_at: @date - 3.months, ends_at: @date - 1.months)

        # 2 users excluded from report because contracts start too late
        create_list(:contract, 2, shop: @shop, starts_at: @date + 3.months)

        # 2 users on reports but without shifts
        2.times do |t|
          user = create(
            :user,
            firstname: "no-shifts-firstname-#{t}",
            lastname: "no-shifts-lastname-#{t}",
            email: "no-shifts-#{t}@skello.io"
          )
          create(
            :contract,
            user: user, shop: @shop,
            starts_at: @date - t.day,
            hourly_wage: 100
          )
        end

        # users which will be included in report with shifts
        hourly_wages = [10, 15, 25]

        # 6 users with one contract and two paid shifts (simple cases)
        6.times do |t|
          user = create(
            :user,
            firstname: "with-shifts-firstname#{t}",
            lastname: "with-shifts-lastname#{t}",
            email: "with-shifts-#{t}@skello.io"
          )
          create(
            :contract,
            user: user,
            shop: @shop,
            starts_at: @date - t.days,
            hourly_wage: hourly_wages[t % 3]
          )
          create(
            :shift, :work,
            user: user, shop: @shop,
            starts_at: @date.change(hour: 8),
            ends_at: @date.change(hour: 9)
          )
          create(
            :shift, :paid_absence,
            user: user, shop: @shop,
            starts_at: @date.change(hour: 10),
            ends_at: @date.change(hour: 11)
          )
          create(
            :shift, :unpaid_absence,
            user: user, shop: @shop,
            starts_at: @date.change(hour: 12),
            ends_at: @date.change(hour: 13)
          )
        end

        # one user with only unpaid absence shift
        unpaid_absence_user = create(
          :user,
          firstname: 'unpaid-absence-shift-firstname',
          lastname: 'unpaid-absence-shift-lastname',
          email: 'unpaid-absence-shift-@skello.io'
        )
        create(
          :contract,
          user: unpaid_absence_user, shop: @shop,
          starts_at: @date - 20.days,
          hourly_wage: 1_000
        )
        create(
          :shift, :unpaid_absence,
          user: unpaid_absence_user, shop: @shop,
          starts_at: @date.change(hour: 10),
          ends_at: @date.change(hour: 16)
        )

        # one user with only unpaid absence shift
        paid_absence_user = create(
          :user,
          firstname: 'paid-absence-shift-firstname',
          lastname: 'paid-absence-shift-lastname',
          email: 'paid-absence-shift-@skello.io'
        )
        create(
          :contract,
          user: paid_absence_user, shop: @shop,
          starts_at: @date - 15.days,
          hourly_wage: 100
        )
        create(
          :shift, :paid_absence,
          user: paid_absence_user, shop: @shop,
          starts_at: @date.change(hour: 10),
          ends_at: @date.change(hour: 14)
        )

        # users with multi contracts on period
        # user_1 has one worked shift on each contract
        user_1 = create(
          :user,
          firstname: 'multi-contracts-firstname-1',
          lastname: 'multi-contracts-lastname-1',
          email: 'multi-contracts-1@skello.io'
        )
        create(
          :contract,
          user: user_1, shop: @shop,
          starts_at: @date - 1.month, ends_at: @date, hourly_wage: 10
        )
        create(
          :contract,
          user: user_1, shop: @shop,
          starts_at: @date + 1.day, ends_at: @date + 5.days, hourly_wage: 12
        )
        create(
          :contract,
          user: user_1, shop: @shop,
          starts_at: @date + 6.days, ends_at: nil, hourly_wage: 15
        )

        create(
          :shift, :work,
          shop: @shop, user: user_1,
          starts_at: @date.change(hour: 10) - 2.days, ends_at: @date.change(hour: 12) - 2.days
        )
        create(
          :shift, :work,
          shop: @shop, user: user_1,
          starts_at: @date.change(hour: 10) + 2.days, ends_at: @date.change(hour: 12) + 2.days
        )
        create(
          :shift, :work,
          shop: @shop, user: user_1,
          starts_at: @date.change(hour: 10) + 7.days,
          ends_at: @date.change(hour: 12) + 7.days
        )

        # user_2 has 2 shifts on 2 contracts of this shop, 1 shift on another shop
        user_2 = create(:user, firstname: 'multi-contracts-firstname-2',
                               lastname: 'multi-contracts-lastname-2',
                               email: 'multi-contracts-2@skello.io')
        create(:contract, user: user_2, shop: @shop,
                          starts_at: @date - 1.month - 1.day, ends_at: @date, hourly_wage: 10)
        create(:contract, user: user_2, shop: @shop,
                          starts_at: @date + 1.day, ends_at: @date + 5.days, hourly_wage: 12)
        create(:contract, user: user_2, shop: @shop,
                          starts_at: @date + 6.days, ends_at: nil, hourly_wage: 15)

        create(
          :shift, :work,
          shop: @shop, user: user_2,
          starts_at: @date.change(hour: 10) - 2.days, ends_at: @date.change(hour: 12) - 2.days
        )
        create(
          :shift, :work,
          shop: create(:shop), user: user_2,
          starts_at: @date.change(hour: 10) + 2.days, ends_at: @date.change(hour: 12) + 2.days
        )
        create(
          :shift, :work,
          shop: @shop, user: user_2,
          starts_at: @date.change(hour: 10) + 7.days, ends_at: @date.change(hour: 12) + 7.days
        )

        # user_3 has a shift on each contract of different kind (worked, paid absence, unpaid_absence)
        user_3 = create(
          :user,
          firstname: 'multi-contracts-firstname-3',
          lastname: 'multi-contracts-lastname-3',
          email: 'multi-contracts-3@skello.io'
        )
        create(
          :contract,
          user: user_3, shop: @shop,
          starts_at: @date - 1.month + 1.day, ends_at: @date, hourly_wage: 10
        )
        create(
          :contract,
          user: user_3, shop: @shop,
          starts_at: @date + 1.day, ends_at: @date + 5.days, hourly_wage: 12
        )
        create(
          :contract,
          user: user_3, shop: @shop,
          starts_at: @date + 6.days, ends_at: nil, hourly_wage: 15
        )

        create(
          :shift, :work,
          shop: @shop, user: user_3,
          starts_at: @date.change(hour: 10) - 2.days,
          ends_at: @date.change(hour: 12) - 2.days
        )
        create(
          :shift, :paid_absence,
          shop: @shop, user: user_3,
          starts_at: @date.change(hour: 10) + 2.days, ends_at: @date.change(hour: 12) + 2.days
        )
        create(
          :shift, :unpaid_absence,
          shop: @shop, user: user_3,
          starts_at: @date.change(hour: 10) + 7.days, ends_at: @date.change(hour: 12) + 7.days
        )
      end

      it 'runs the generate service and outputs a valid report' do
        test_filepath = "#{Rails.root}/tmp/test_export.csv"
        reference_filepath = "#{Rails.root}/spec/export/test_file.csv"
        csv_options = { col_sep: ';' }

        ShopMonthlyReportGenerateService.new(
          @shop.id,
          @date,
          test_filepath
        ).run

        csv_file = CSV.read(test_filepath, csv_options)
        test_csv_file = CSV.read(reference_filepath, csv_options)
        csv_file.each_with_index do |row, index|
          expect(row).to eq test_csv_file[index]
        end
      end
    end
  end
end
