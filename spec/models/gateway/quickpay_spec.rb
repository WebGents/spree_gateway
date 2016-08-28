require 'spec_helper'

describe Spree::Gateway::Quickpay do

  let!(:country) { create(:country, name: 'Denmark', iso_name: 'DENMARK', iso3: 'DNK', iso: 'DK', numcode: 208) }
  let!(:address) { create(:address,
    firstname: 'Jens', lastname: 'Hanssen',
    address1: 'Julebrygvej 1', address2: '1 tv',
    city: 'København', zipcode: '1778',
    phone: '+45 10 00 00 00', country: country)
  }

  before do
    Spree::Gateway.update_all(active: false)
    @gateway = Spree::Gateway::Quickpay.create!(name: 'Quickpay', active: true)
    @gateway.preferences = {
      api_key: '49baef7a21741e7a446d6984b72e1af53141d715a0f206830cc341e118595c6d'
    }
    @gateway.save!
    @credit_card = create(:credit_card,
        verification_value: '123',
        number:             '100000000000008',
        month:              12,
        year:               Time.now.year + 1,
        name:               "#{address.firstname} #{address.lastname}",
        cc_type:            'visa')
  end

  describe '.provider_class' do
    it 'is a Quickpay gateway' do
      expect(@gateway.provider_class).to eq ::ActiveMerchant::Billing::QuickpayV10Gateway
    end
  end

  describe '.payment_profiles_supported?' do
    it 'return true' do
      expect(@gateway.payment_profiles_supported?).to be true
    end
  end

  describe 'payment profile creation' do
    before do

      order = create(:order_with_totals, bill_address: address, ship_address: address)
      order.update_with_updater!
      @payment = create(:payment, source: @credit_card, order: order, payment_method: @gateway, amount: 10.00)
    end

    context 'when a credit card is created' do
      it "stores the profile id on the souce record" do
        expect(@payment.source.gateway_customer_profile_id).to be_present
        expect(@payment.source.gateway_customer_profile_id).to match /\A\d+\z/
      end
    end
  end

  describe '#authorize' do
    context 'credit card has a payment profile' do
      before(:each) do
        @profile_id = '12345'
        @credit_card.update_attributes(gateway_customer_profile_id: @profile_id)
      end

      it "calls provider#authorize using the profile id" do
        expect(@gateway.provider).to receive(:authorize).with(20, @profile_id)
        @gateway.authorize(20, @profile_id)
      end
    end
  end
end
