class FinanceNote < ApplicationRecord
  delegate :order, to: :order_settlement, prefix: false, allow_nil: true

  def discount_amount
    if order.imported
      super
    else
      invoice_amount
    end
  end

  def discount_price
    if order.imported
      super
    else
      FinanceNote.invoice_price(order)
    end
  end

  def discount_tax
    if order.imported
      super
    else
      FinanceNote.invoice_tax(order)
    end
  end
end
