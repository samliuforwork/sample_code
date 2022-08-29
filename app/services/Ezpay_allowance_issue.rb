module Ezpay
  class AllowanceIssue
    extend APIEzpayHelper

    class << self
      def send_api(order)
        response = create(allowance_params(order), Settings.ezpay_invoice.allowance_url)
        parse_response = JSON.parse(response)
        response_status = parse_response['Status'] == 'SUCCESS' ? 'success' : 'failure'
        InvoiceAPILog.create!(api: 'allowance', order_id: order.id, merchant_order_no: order.parent.order_settlement.finance_note.merchant_order_no, status: response_status, content: response)

        response_status == 'success' ? api_update_allowance(parse_response, order) : resend_allowance(order)
      end

      private
      def allowance_params(order)
        finance_note = order.parent.order_settlement.finance_note
        post_data = {
          RespondType: 'JSON',
          Version: 1.3,
          Status: 1,
          TimeStamp: Time.now.to_i,
          InvoiceNo: order.parent.order_settlement.try_finance_note.invoice_serial,
          MerchantOrderNo: finance_note.merchant_order_no,
          ItemCount: 1,
          ItemName: order.parent.invoice.item_name,
          ItemUnit: order.parent.invoice.item_unit,
          TotalAmt: finance_note.discount_amount.to_i,
          ItemPrice: finance_note.discount_price.to_i,
          ItemAmt: finance_note.discount_price.to_i,
          ItemTaxAmt: finance_note.discount_tax.to_i
        }

        {
          MerchantID_: Settings.ezpay_invoice.merchant_id,
          PostData_: encrypt(post_data)
        }
      end

      def api_update_allowance(parse_response, order)
        return unless validate_check_code(parse_response['Result']) == 'SUCCESS'
    
        result = JSON.parse(parse_response['Result'])
        order.order_settlement.finance_note.update(
          invoice_serial: result['InvoiceNumber'],
          discount_at: Time.now.strftime('%Y-%m-%d %T'),
          merchant_order_no: result['MerchantOrderNo'],
          discount_invoice_serial: result['AllowanceNo']
        )
      end

      def resend_allowance(order)
        ResendAllowanceJob.set(wait: Settings.ezpay_invoice.resend_time, priority: 10).perform_later(order)
      end
    end
  end
end
