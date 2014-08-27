class ActiveSupport::Base32
  RFC3548 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

  def initialize(alphabet = RFC3548)
    @alphabet = alphabet
  end

  def encode(string)
    string.bytes.in_groups_of(5).map do |chunk|
      encode_chunk(chunk)
    end.flatten.join
  end

  def decode(string)
    string.bytes.in_groups_of(8).map do |chunk|
      decode_chunk(chunk)
    end.flatten.pack('C*')
  end

  private

  def encode_chunk(chunk)
    characters_needed = (chunk.compact.size * 8.0 / 5.0).ceil
    forty_bits = chunk.inject(0) {|memo, byte| (memo << 8) + (byte || 0)}
    8.times.map {|i| @alphabet[(forty_bits >> (i * 5)) & 0x1f] }.reverse.take(characters_needed)
  end

  def decode_chunk(chunk)
    characters_encoded = (chunk.compact.size * 5.0 / 8.0).floor
    forty_bits = chunk.inject(0) {|memo, byte| (memo << 5) + (@alphabet.bytes.index(byte) || 0)}
    5.times.map {|i| (forty_bits >> (i * 8)) & 0xff }.reverse.take(characters_encoded)
  end
end
