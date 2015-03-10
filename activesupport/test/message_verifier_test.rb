require 'abstract_unit'
require 'openssl'
require 'active_support/time'
require 'active_support/json'
require 'active_support/core_ext/string'

class MessageVerifierTest < ActiveSupport::TestCase

  class JSONSerializer
    def dump(value)
      ActiveSupport::JSON.encode(value)
    end

    def load(value)
      ActiveSupport::JSON.decode(value)
    end
  end

  class TestEncoding
    PREFIX = "test-prefix"

    def encode(value)
      PREFIX + value.reverse
    end

    def decode(value)
      value.from(PREFIX.length).reverse
    end
  end

  class NullEncoding
    def encode(value)
      value
    end

    def decode(value)
      value
    end
  end

  class NullSerializer
    def dump(value)
      value
    end

    def load(value)
      value
    end
  end

  def setup
    @verifier = ActiveSupport::MessageVerifier.new("Hey, I'm a secret!")
    @data = { :some => "data", :now => Time.local(2010) }
  end

  def test_valid_message
    data, hash = @verifier.generate(@data).split("--")
    assert !@verifier.valid_message?(nil)
    assert !@verifier.valid_message?("")
    assert !@verifier.valid_message?("#{data.reverse}--#{hash}")
    assert !@verifier.valid_message?("#{data}--#{hash.reverse}")
    assert !@verifier.valid_message?("purejunk")
  end

  def test_simple_round_tripping
    message = @verifier.generate(@data)
    assert_equal @data, @verifier.verified(message)
    assert_equal @data, @verifier.verify(message)
  end

  def test_verified_returns_false_on_invalid_message
    assert !@verifier.verified("purejunk")
  end

  def test_verify_exception_on_invalid_message
    assert_raise(ActiveSupport::MessageVerifier::InvalidSignature) do
      @verifier.verify("purejunk")
    end
  end

  def test_alternative_serialization_method
    prev = ActiveSupport.use_standard_json_time_format
    ActiveSupport.use_standard_json_time_format = true
    verifier = ActiveSupport::MessageVerifier.new("Hey, I'm a secret!", :serializer => JSONSerializer.new)
    message = verifier.generate({ :foo => 123, 'bar' => Time.utc(2010) })
    exp = { "foo" => 123, "bar" => "2010-01-01T00:00:00.000Z" }
    assert_equal exp, verifier.verified(message)
    assert_equal exp, verifier.verify(message)
  ensure
    ActiveSupport.use_standard_json_time_format = prev
  end

  def test_alternative_encoding_method
    verifier = ActiveSupport::MessageVerifier.new("Hey, I'm a secret!", :encoding => TestEncoding.new)
    message = { :foo => 123, 'bar' => Time.utc(2010) }
    verified_message = verifier.generate(message)
    assert verified_message.starts_with?(TestEncoding::PREFIX)
    assert_equal message, verifier.verified(verified_message)
  end

  def test_encode_full_message
    verifier = ActiveSupport::MessageVerifier.new("Hey, I'm a secret!", :encode_full_message => true)
    message = { :foo => 123, 'bar' => Time.utc(2010) }
    verified_message = verifier.generate(message)
    decoded_message = Base64.strict_decode64(verified_message)

    assert_equal message, Marshal.load(decoded_message.split("--").first)
    assert_equal message, verifier.verified(verified_message)
  end

  def test_digest_found_if_message_contains_separator
    verifier = ActiveSupport::MessageVerifier.new("Hey, I'm a secret!", encoding: NullEncoding.new, serializer: NullSerializer.new)
    message = "--------"
    verified_message = verifier.generate(message)

    assert_equal message, verifier.verified(verified_message)
  end

  def test_raise_error_when_argument_class_is_not_loaded
    # To generate the valid message below:
    #
    #   AutoloadClass = Struct.new(:foo)
    #   valid_message = @verifier.generate(foo: AutoloadClass.new('foo'))
    #
    valid_message = "BAh7BjoIZm9vbzonTWVzc2FnZVZlcmlmaWVyVGVzdDo6QXV0b2xvYWRDbGFzcwY6CUBmb29JIghmb28GOgZFVA==--f3ef39a5241c365083770566dc7a9eb5d6ace914"
    exception = assert_raise(ArgumentError, NameError) do
      @verifier.verified(valid_message)
    end
    assert_includes ["uninitialized constant MessageVerifierTest::AutoloadClass",
                    "undefined class/module MessageVerifierTest::AutoloadClass"], exception.message
    exception = assert_raise(ArgumentError, NameError) do
      @verifier.verify(valid_message)
    end
    assert_includes ["uninitialized constant MessageVerifierTest::AutoloadClass",
                    "undefined class/module MessageVerifierTest::AutoloadClass"], exception.message
  end

  def test_raise_error_when_secret_is_nil
    exception = assert_raise(ArgumentError) do
      ActiveSupport::MessageVerifier.new(nil)
    end
    assert_equal exception.message, 'Secret should not be nil.'
  end
end
