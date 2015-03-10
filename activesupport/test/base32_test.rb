require 'abstract_unit'
require 'active_support/base32'

class Base32Test < ActiveSupport::TestCase
  setup do
    @encoder = ActiveSupport::Base32.new
  end

  test "encodes into base32 " do
    assert_equal "me", @encoder.encode("a")
    assert_equal "ifqxezdwmfzgw", @encoder.encode("Aardvark")
    assert_equal "i5wg65ldmvzxizls", @encoder.encode("Gloucester")
  end

  test "encoding less than five characters" do
    assert_round_trip "a"
  end

  test "encoding more than five characters" do
    assert_round_trip "123456"
  end

  test "encoding non-ASCII bytes" do
    assert_round_trip "çåƒé-søçîé†¥"
  end

  test "encoding non UTF-8 text" do
    message = "çåƒé-søçîé†¥".encode("UTF-32BE")
    encoded = @encoder.encode(message)
    decoded = @encoder.decode(encoded)
    assert_equal message.bytes, decoded.bytes
  end

  test "decoding invalid content" do
    exception = assert_raise(ArgumentError) { @encoder.decode "#" }
    assert_equal "invalid base32", exception.message
  end

  test "using a case-sensitive alphabet" do
    @encoder = ActiveSupport::Base32.new case_sensitive: true
    encoded = @encoder.encode "çåƒé-søçîé†¥"

    assert_equal "çåƒé-søçîé†¥", @encoder.decode(encoded.downcase)
    assert_raise(ArgumentError) { @encoder.decode(encoded.upcase) }
  end

  test "using a case-insensitive alphabet" do
    @encoder = ActiveSupport::Base32.new case_sensitive: false
    encoded = @encoder.encode "çåƒé-søçîé†¥"

    assert_equal @encoder.decode(encoded.upcase), @encoder.decode(encoded.downcase)
  end

  private
    def assert_round_trip(input)
      encoded = @encoder.encode(input)
      decoded = @encoder.decode(encoded)
      assert_equal input, decoded
    end
end
