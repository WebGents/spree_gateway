module Spree
  class Gateway::Quickpay < Gateway
    preference :api_key, :string

    def provider_class
      ActiveMerchant::Billing::QuickpayV10Gateway
    end

    def authorize(money, creditcard, options = {})
      if creditcard.gateway_customer_profile_id
        payment_method = creditcard.gateway_customer_profile_id
      else
        payment_method = creditcard
      end
      provider.authorize(money, payment_method, options)
    end

    def payment_profiles_supported?
      true
    end

    def create_profile(payment)
      if payment.source.gateway_customer_profile_id.nil? && payment.source.number.present?
        response = provider.store(payment.source)

        if response.success?
          id = response.authorization
          payment.source.update_attributes!(gateway_customer_profile_id: id)
        else
          payment.send(:gateway_error, response.message)
        end
      end
    end
  end
end
