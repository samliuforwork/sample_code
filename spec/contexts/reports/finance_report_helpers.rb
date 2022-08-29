RSpec.shared_context 'finance report payment sheet' do
  include_context 'order with auditing settlement'

  let(:payment_details_attributes) {
    [
      {
        listing: 'initial',
        payment_type: 'cash',
        amount: 8000.to_d,
        payterm: 1,
        identity: 'A1200000000',
        not_card_holder: true,
        bank: 'HiBank',
        expire_month: 9,
        expire_year: 2099,
        card_number: '9999-8888-7777-6666',
        payer: 'Jason Weng',
        card_auth_date: '2022-05-07',
        card_auth_code: 'abc123',
        check_no: 'AB123456789',
        checking_account: '02912345-666666',
        branch: 'Momo',
        checking_date: '2025-05-07',
        checking_issuer: 'Sam'
      },
      {
        listing: 'final',
        payment_type: 'creditcard',
        card_type: 'master',
        amount: 4710.to_d,
        payterm: 2,
        identity: 'B2200000000',
        not_card_holder: false,
        bank: 'MyBank',
        expire_month: 6,
        expire_year: 2035,
        card_number: '1111-2222-3333-4444',
        payer: 'David Chen',
        card_auth_date: '2022-01-01',
        card_auth_code: 'bd456',
        check_no: 'CD223434352',
        checking_account: '02312312-888888',
        branch: 'ABC',
        checking_date: '2025-12-31',
        checking_issuer: 'Mike'
      }
    ]
  }
  let!(:finance_note) { order.order_settlement.create_finance_note(
      discount_amount: 200.0,
      discount_invoice_serial: 'ABC123456',
      discount_at: '2022-05-07'
    )
  }
  let(:expected_payment_columns) {
    [
      {
        UUID: '202101-10601-0001',
        order_type: I18n.t('xlsx:purchase_order'),
        pay_listing: I18n.t('listing:initial'),
        payment_type: I18n.t('payment_method:cash'),
        order_first_submitted_at: '01-16 12:00',
        order_date: '2020/06/04',
        external_id: 'KK123456780',
        buyer_name: 'Kevin',
        order_category: I18n.t('Junior High School'),
        sales_channel: 'company',
        order_status_updated_at: '2022/07/01',
        settlement_status: I18n.t('xlsx:auditing'),
        settlement_status_changed_at: '2022/07/01',
        email: 'kevin@example.com',
        invoice_type: I18n.t('invoice_type_2sheets'),
        invoice_digital_device_type: '0',
        invoice_digital_device_number: '/00ABCD.',
        invoice_issue_to: 'Kevin',
        invoice_address: 'ABCADDRESS',
        invoice_price: 12105,
        invoice_tax: 605.0,
        invoice_amount: 12710.0,
        pay_for: 'book',

        amount: 8000.0,
        payterm: Settings.payterm_providers[1],
        identity: 'A1200000000',
        not_card_holder: 'V',
        bank: 'HiBank',
        expire_month: 9,
        expire_year: 2099,
        card_number: '9999-8888-7777-6666',
        payer: 'Jason Weng',
        card_auth_date: '2022/05/07',
        card_auth_code: 'abc123',
        check_no: 'AB123456789',
        checking_account: '02912345-666666',
        branch: 'Momo',
        checking_date: '2025/05/07',
        checking_issuer: 'Sam',
        card_type: nil,
        order_status: I18n.t('order_status:verified'),
        discount_at: '2022/05/07',
        discount_invoice_serial: 'ABC123456',
        discount_price: 12105,
        discount_tax: 605.0,
        discount_amount: 12710.0
      },
      {
        UUID: '202101-10601-0001',
        order_type: I18n.t('xlsx:purchase_order'),
        pay_listing: I18n.t('listing:final'),
        payment_type: I18n.t('payment_method:creditcard'),
        order_first_submitted_at: '01-16 12:00',
        order_date: '2020/06/04',
        external_id: 'KK123456780',
        buyer_name: 'Kevin',
        order_category: I18n.t('Junior High School'),
        sales_channel: 'company',
        order_status_updated_at: '2022/07/01',
        settlement_status: I18n.t('xlsx:auditing'),
        settlement_status_changed_at: '2022/07/01',
        email: 'kevin@example.com',
        invoice_type: I18n.t('invoice_type_2sheets'),
        invoice_digital_device_type: '0',
        invoice_digital_device_number: '/00ABCD.',
        invoice_issue_to: 'Kevin',
        invoice_address: 'ABC_ADDRESS',
        invoice_price: 12105,
        invoice_tax: 605.0,
        invoice_amount: 12710.0,
        pay_for: 'book',

        amount: 4710.0,
        payterm: Settings.payterm_providers[2],
        identity: 'B2200000000',
        not_card_holder: nil,
        bank: 'MyBank',
        expire_month: 6,
        expire_year: 2035,
        card_number: '1111-2222-3333-4444',
        payer: 'David Chen',
        card_auth_date: '2022/01/01',
        card_auth_code: 'bd456',
        check_no: 'CD223434352',
        checking_account: '02312312-888888',
        branch: 'ABC',
        checking_date: '2025/12/31',
        checking_issuer: 'Mike',
        card_type: 'MASTER',
        order_status: I18n.t('order_status:verified'),
        discount_at: '2022/05/07',
        discount_invoice_serial: 'ABC123456',
        discount_price: 12105,
        discount_tax: 605.0,
        discount_amount: 12710.0
      }
    ]
  }
end

RSpec.shared_context 'finance report reconciliation sheet' do
  include_context 'order with auditing settlement'

  let(:payment_notes_attributes) {
    [
      {
        payment_type: 0,
        payment_method: 1,
        amount: '20.99',
        due_date: '2020-05-07 13:27:34',
        received_at: '2020-05-07 13:27:34',
        received_amount: '9.99',
        vendor_fee: '5.55',
        bank: 'CityBank'
      },
      {
        payment_type: 1,
        payment_method: 2,
        amount: '100',
        due_date: '2025-05-07 13:27:34',
        received_at: '2025-05-07 13:27:34',
        received_amount: '50',
        vendor_fee: '10',
        bank: 'WorldBank'
      }
    ]
  }
  let!(:payment_notes) {
    finance_note = order.order_settlement.create_finance_note(discount_amount: 200.0, discount_invoice_serial: 'ABC123456', discount_at: '2022-05-07')
    finance_note.payment_notes.create(payment_notes_attributes)
  }
  let(:expected_reconciliation_columns) {
    [
      {
        UUID: '202101-10601-0001',
        order_type: I18n.t('xlsx:purchase_order'),
        order_first_submitted_at: '01-16 12:00',
        order_date: '2020/06/04',
        buyer_name: 'Kevin',
        order_category: I18n.t('Junior High School'),
        settlement_status: I18n.t('xlsx:auditing'),
        sales_channel: 'company',
        order_status: I18n.t('order_status:verified'),
        invoice_amount: 12710.0,

        payment_or_return: I18n.t('payment_type:payment'),
        payment_type: I18n.t('payment_method:creditcard'),
        pay_return_amount: 20.99,
        due_date: '2020/05/07',
        received_at: '2020/05/07',
        received_amount: 9.99,
        vendor_fee: 5.55,
        pay_return_bank: 'CityBank',
        discount_at: '2022/05/07',
        discount_invoice_serial: 'ABC123456',
        discount_amount: 12710.0
      },
      {
        UUID: '202101-10601-0001',
        order_type: I18n.t('xlsx:purchase_order'),
        order_first_submitted_at: '01-16 12:00',
        order_date: '2020/06/04',
        buyer_name: 'Kevin',
        order_category: I18n.t('Junior High School'),
        settlement_status: I18n.t('xlsx:auditing'),
        sales_channel: 'company',
        order_status: I18n.t('order_status:verified'),
        invoice_amount: 12710,

        payment_or_return: I18n.t('payment_type:returning'),
        payment_type: I18n.t('payment_method:check'),
        pay_return_amount: 100.0,
        due_date: '2025/05/07',
        received_at: '2025/05/07',
        received_amount: 50.0,
        vendor_fee: 10.0,
        pay_return_bank: 'WorldBank',
        discount_at: '2022/05/07',
        discount_invoice_serial: 'ABC123456',
        discount_amount: 12710.0
      }
    ]
  }
end