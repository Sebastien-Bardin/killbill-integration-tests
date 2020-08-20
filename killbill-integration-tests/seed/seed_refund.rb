# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('..', __dir__)
$LOAD_PATH.unshift File.expand_path(__dir__)

require 'seed_base'

module KillBillIntegrationSeed
  class TestRefund < TestSeedBase
    def setup
      setup_seed_base
    end

    def teardown
      teardown_base
    end

    #   Show the refund and also the fact that account has a balance since there were no adjustment.

    def test_seed_refund_no_adj
      data = {}
      data[:name] = 'Jean-Baptiste Poquelin'
      data[:external_key] = 'jeanpoquelin'
      data[:email] = 'jeanpoquelin@kb.com'
      data[:currency] = 'EUR'
      data[:time_zone] = 'Europe/Paris'
      data[:address1] = '17, rue Saint-Honore'
      data[:address2] = nil
      data[:postal_code] = '75000'
      data[:company] = nil
      data[:city] = 'Paris'
      data[:state] = 'Region Parisienne'
      data[:country] = 'France'
      data[:locale] = 'fr_FR'

      @jeanpoquelin = create_account_with_data(@user, data, @options)
      add_payment_method(@jeanpoquelin.account_id, '__EXTERNAL_PAYMENT__', true, nil, @user, @options)

      base1 = create_entitlement_base(@jeanpoquelin.account_id, 'reserved-metal', 'MONTHLY', 'DEFAULT', @user, @options)
      wait_for_expected_clause(1, @jeanpoquelin, @options, &@proc_account_invoices_nb)

      # Second invoice
      kb_clock_add_days(31, nil, @options) # 2015-09-01
      wait_for_expected_clause(2, @jeanpoquelin, @options, &@proc_account_invoices_nb)

      kb_clock_add_days(1, nil, @options) # 2015-09-02

      base1.cancel(@user, nil, nil, nil, 'IMMEDIATE', 'END_OF_TERM', nil, @options)

      payments = get_payments_for_account(@jeanpoquelin.account_id, @options)

      refund(payments[1].payment_id, payments[1].purchased_amount, nil, @user, @options)
    end

    #       Show the refund and also the fact that account has no balance since we iia adjusted the invoice

    def test_seed_refund_iia
      data = {}
      data[:name] = 'Agostino Giordano'
      data[:external_key] = 'agostinogiordano8'
      data[:email] = 'agostinogiordano8@kb.com'
      data[:currency] = 'EUR'
      data[:time_zone] = 'Europe/Rome'
      data[:address1] = '3 Viale Abruzzi'
      data[:address2] = nil
      data[:postal_code] = '20010'
      data[:company] = nil
      data[:city] = 'Milan'
      data[:state] = 'Lombardy'
      data[:country] = 'Italy'
      data[:locale] = 'it_IT'

      @agostinogiordano = create_account_with_data(@user, data, @options)
      add_payment_method(@agostinogiordano.account_id, '__EXTERNAL_PAYMENT__', true, nil, @user, @options)

      # Generate first invoice for the annual plan
      base1 = create_entitlement_base(@agostinogiordano.account_id, 'reserved-metal', 'MONTHLY', 'DEFAULT', @user, @options)
      wait_for_expected_clause(1, @agostinogiordano, @options, &@proc_account_invoices_nb)

      # Second invoice
      kb_clock_add_days(31, nil, @options) # 2015-09-01
      wait_for_expected_clause(2, @agostinogiordano, @options, &@proc_account_invoices_nb)

      kb_clock_add_days(1, nil, @options) # 2015-09-02

      base1.cancel(@user, nil, nil, nil, 'IMMEDIATE', 'END_OF_TERM', nil, @options)

      payments = get_payments_for_account(@agostinogiordano.account_id, @options)

      invoice_payment = get_invoice_payment(payments[1].payment_id, @options)

      invoice = get_invoice_by_id(invoice_payment.target_invoice_id, @options)

      adjustments = []
      adjustments << { invoice_item_id: invoice.items[0].invoice_item_id,
                       currency: 'EUR',
                       amount: invoice.items[0].amount }

      refund(payments[1].payment_id, payments[1].purchased_amount, adjustments, @user, @options)
    end
  end
end
