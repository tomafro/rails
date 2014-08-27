require 'abstract_unit'

require 'active_support/base32'
require 'active_support/core_ext/array'

class Base32Test < ActiveSupport::TestCase
  setup do
    @encoder = ActiveSupport::Base32.new
  end

  test "encodes into base32 " do
    assert_equal "ME", @encoder.encode("a")
    assert_equal "IFQXEZDWMFZGW", @encoder.encode("Aardvark")
    assert_equal "I5WG65LDMVZXIZLS", @encoder.encode("Gloucester")
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
    assert_round_trip "çåƒé-søçîé†¥".encode("UTF-32BE")
  end

  private

  def assert_round_trip(input)
    assert_equal input, @encoder.decode(@encoder.encode(input)).force_encoding(input.encoding)
  end
end
