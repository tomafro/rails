require 'base64'

class ActiveSupport::StrictBase64Encoder
  def self.encode(data)
    Base64.strict_encode64(data)
  end

  def self.decode(data)
    Base64.strict_decode64(data)
  end
end
