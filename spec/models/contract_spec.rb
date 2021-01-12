require 'rails_helper'

describe Contract, type: :model do
  let!(:shop) { create(:shop, name: 'Skello Shop') }
  let!(:user) { create(:user, firstname: 'John', lastname: 'Doe') }

  describe 'scopes' do
    describe '#active_at' do
      before do
        @a = create(:contract, starts_at: '2020-01-15', ends_at: '2020-01-25') # NO
        @b = create(:contract, starts_at: '2020-01-15', ends_at: '2020-02-15') # YES
        @c = create(:contract, starts_at: '2020-02-01', ends_at: '2020-02-20') # YES
        @d = create(:contract, starts_at: '2020-02-15', ends_at: '2020-03-15') # YES
        @e = create(:contract, starts_at: '2020-03-01', ends_at: '2020-03-15') # NO
        @f = create(:contract, starts_at: '2020-01-16', ends_at: nil) # YES
        @g = create(:contract, starts_at: '2020-02-16', ends_at: nil) # YES
        @h = create(:contract, starts_at: '2020-03-16', ends_at: nil) # NO
      end

      it 'returns contracts active on given period' do
        period_start = Date.parse('2020-02-01')
        period_end = Date.parse('2020-02-28')

        expect(Contract.active_at(period_start, period_end)).to match_array(
          [@b, @c, @d, @f, @g]
        )
      end
    end
  end

  describe 'validations' do
    context 'valid contract' do
      it 'validates a contract if it is valid' do
        contract = build(
          :contract,
          user_id: user.id,
          shop_id: shop.id,
          hourly_wage: 15,
          starts_at: DateTime.current
        )

        expect(contract).to be_valid
      end
    end

    describe 'user association' do
      it 'does not validate if user is missing' do
        contract = build(
          :contract,
          shop_id: shop.id,
          user_id: nil,
          hourly_wage: 15,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:user].pluck(:error)).to match_array [:blank]
      end

      it 'does not validate if user is missing' do
        contract = build(
          :contract,
          shop_id: shop.id,
          user_id: User.last.id + 1,
          hourly_wage: 15,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:user].pluck(:error)).to match_array [:blank]
      end
    end

    describe 'shop association' do
      it 'does not validate if shop is missing' do
        contract = build(
          :contract,
          user_id: user.id,
          shop_id: nil,
          hourly_wage: 15,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:shop].pluck(:error)).to match_array [:blank]
      end

      it 'does not validate if shop does not exist' do
        contract = build(
          :contract,
          shop_id: 0,
          user_id: user.id,
          hourly_wage: 15,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:shop].pluck(:error)).to match_array [:blank]
      end
    end

    describe 'hourly_wage' do
      it 'does not validate if hourly wage is missing' do
        contract = build(
          :contract,
          user_id: user.id,
          shop_id: shop.id,
          hourly_wage: nil,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:hourly_wage].pluck(:error)).to match_array %i[blank not_a_number]
      end

      it 'does not validate if hourly wage is negative' do
        contract = build(
          :contract,
          user_id: user.id,
          shop_id: shop.id,
          hourly_wage: -10,
          starts_at: DateTime.current
        )

        expect(contract).to be_invalid
        expect(contract.errors.details[:hourly_wage].pluck(:error)).to match_array [:greater_than]
      end
    end

    describe 'starts_at' do
      let!(:date) { DateTime.new(2020, 9, 1, 10, 15, 45) }

      context 'start_at is at midnight' do
        it 'saves the contract with a starts_at at midnight' do
          contract = Contract.create!(
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date
          )

          expect(contract.starts_at).to eq date.beginning_of_day
        end
      end

      context 'endless contract uniqueness' do
        it 'does not validate an endless contract if an other is already existing' do
          Contract.create!(
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 10.days,
            ends_at: nil
          )

          new_contract = build(
            :contract,
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 5.days,
            ends_at: nil
          )

          expect(new_contract).to be_invalid
          expect(new_contract.errors.details[:base].pluck(:error)).to include(:overlapping_contract)
        end
      end

      context '#no_contract_overlap' do
        before do
          Contract.create!(
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 20.days,
            ends_at: date - 10.days
          )
        end

        it 'does not validate if it starts before than other but ends during' do
          new_contract = build(
            :contract,
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 25.days,
            ends_at: date - 15.days
          )

          expect(new_contract).to be_invalid
          expect(new_contract.errors.details[:base].pluck(:error)).to include(:overlapping_contract)
        end

        it 'does not validate if it starts during than other and ends after' do
          new_contract = build(
            :contract,
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 15.days,
            ends_at: date - 5.days
          )

          expect(new_contract).to be_invalid
          expect(new_contract.errors.details[:base].pluck(:error)).to include(:overlapping_contract)
        end

        it 'does not validate if it starts and ends during the other one' do
          new_contract = build(
            :contract,
            user_id: user.id,
            shop_id: shop.id,
            hourly_wage: 10,
            starts_at: date - 18.days,
            ends_at: date - 12.days
          )

          expect(new_contract).to be_invalid
          expect(new_contract.errors.details[:base].pluck(:error)).to include(:overlapping_contract)
        end
      end
    end
  end

  describe 'methods' do
    describe '#contains?' do
      it 'returns true if temporary contract contains given period' do
        contract = create(:contract, starts_at: '2020-03-01', ends_at: nil)

        expect(contract.contains?(Date.new(2020, 2, 1), Date.new(2020, 2, 28))).to eq false
        expect(contract.contains?(Date.new(2020, 2, 15), Date.new(2020, 3, 15))).to eq false
        expect(contract.contains?(Date.new(2020, 3, 1), Date.new(2020, 3, 31))).to eq true
        expect(contract.contains?(Date.new(2020, 3, 15), Date.new(2020, 4, 15))).to eq true
        expect(contract.contains?(Date.new(2020, 4, 1), Date.new(2020, 4, 30))).to eq true
      end

      it 'returns true if permanent contract contains with given period' do
        contract = create(:contract, starts_at: '2020-03-01', ends_at: '2020-03-31')

        expect(contract.contains?(Date.new(2020, 2, 1), Date.new(2020, 2, 28))).to eq false
        expect(contract.contains?(Date.new(2020, 2, 15), Date.new(2020, 3, 15))).to eq false
        expect(contract.contains?(Date.new(2020, 3, 1), Date.new(2020, 3, 31))).to eq true
        expect(contract.contains?(Date.new(2020, 3, 15), Date.new(2020, 4, 15))).to eq false
        expect(contract.contains?(Date.new(2020, 4, 1), Date.new(2020, 4, 30))).to eq false
      end
    end
  end
end
