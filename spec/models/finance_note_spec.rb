require 'rails_helper'

RSpec.describe FinanceNote, type: :model do
  include_context 'valid sales people'
  include_context 'valid price lists'
  let(:order) { PurchaseOrder.create(JSON.parse(file_fixture("order_verifying.json").read)) }
  let(:order_with_tax) { 
    order.invoice.tax_type = 'taxable'
    order.invoice.tax_rate = 5
    order
  }
  let(:imported_order) { 
    order.imported = true
    order.order_settlement.try_finance_note.discount_tax = 567
    order.order_settlement.finance_note.discount_price = 45678
    order.order_settlement.finance_note.discount_amount = 12345
    order
  }
  subject { build(:finance_note) }

  describe 'validate' do
    it { should validate_length_of(:invoice_serial).is_at_most(128) }
    it { should validate_length_of(:discount_invoice_serial).is_at_most(128) }
  end

  describe '.invoice_price' do
    context 'with tax rate' do
      it 'returns invoice_price' do
        expect(described_class.invoice_price(order_with_tax)).to eq(12105)
      end
    end
  end

  describe '.invoice_tax' do
    context 'with tax rate' do
      it 'retuns invoice tax' do
        expect(described_class.invoice_tax(order_with_tax)).to eq(605)
        expect(described_class.invoice_tax(order_with_tax)).to eq(order.price_info.total - described_class.invoice_price(order))
      end
    end
  end

  describe '#invoice_amount' do
    it 'sum price_info total' do
      expect(order.order_settlement.try_finance_note.invoice_amount).to eq(12710)
    end
  end

  describe '.discount_amount' do
    context 'when imported order' do
      let(:imported_order_discount_amount) { imported_order.order_settlement.finance_note.discount_amount }

      it 'returns discount_amount' do
        expect(imported_order_discount_amount).to eq(12345)
      end
    end

    context 'when not imported order' do
      let(:order_discount_amount) { order.order_settlement.try_finance_note.discount_amount }

      it 'returns invoice_amount' do
        expect(order_discount_amount).to eq(12710)
      end
    end
  end

  describe '.discount_price' do
    context 'when imported order' do
      let(:imported_order_discount_price) { imported_order.order_settlement.finance_note.discount_price }

      it 'returns discount_price' do
        expect(imported_order_discount_price).to eq(45678)
      end
    end

    context 'when not imported order' do
      %w[2sheets 3sheets].each do |sheet|
        let(:discount_price_sheet) { 
          order_with_tax.invoice&.type = sheet
          order_with_tax.order_settlement.try_finance_note.discount_price
        }

        it 'returns invoice_price' do
          expect(discount_price_sheet).to eq(12105)
        end
      end
    end
  end

  describe '.discount_tax' do
    context 'when imported order' do
      let(:imported_order_discount_tax) { imported_order.order_settlement.finance_note.discount_tax }

      it 'returns discount_tax' do
        expect(imported_order_discount_tax).to eq(567)
      end
    end

    context 'when not imported order' do
      %w[2sheets 3sheets].each do |sheet|
        let(:discount_tax_sheet) { 
          order_with_tax.invoice&.type = sheet
          order_with_tax.order_settlement.try_finance_note.discount_tax
        }

        it 'returns invoice_price' do
          expect(discount_tax_sheet).to eq(605)
        end
      end
    end
  end
end
