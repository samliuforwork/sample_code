module APIEzpayHelper
  def create(params, url)
    uri = URI(url)
    response = Net::HTTP.post_form(uri, params)
    response.body.force_encoding('UTF-8')
  end

  def encrypt(data)
    aes = OpenSSL::Cipher.new('AES-256-CBC')
    aes.encrypt
    aes.key = Settings.ezpay_invoice.hash_key
    aes.iv = Settings.ezpay_invoice.hash_iv

    (aes.update(data.to_query) + aes.final).unpack1('H*').upcase
  end

  def validate_check_code(data)
    data = JSON.parse(data)
    check_code = data.delete('CheckCode')
    data.slice!('InvoiceTransNo', 'MerchantID', 'MerchantOrderNo', 'RandomNum', 'TotalAmt')
    query_str = "HashIV=#{Settings.ezpay_invoice.hash_iv}&#{data.to_query}&HashKey=#{Settings.ezpay_invoice.hash_key}"

    Digest::SHA256.hexdigest(query_str).upcase == check_code
  end
end
