#!/usr/bin/env ruby

require "openssl"
require "base64"
require "json"

ISSUER  = "https://ia1.dev.localhost"
KID     = "defaultECFedSign"
KEY_PATH = "ia1/lighthouse/data/signing/federation_ES256.pem"

def b64url(bin)
  Base64.urlsafe_encode64(bin, padding: false)
end

def curve_name(group)
  case group.curve_name
  when "prime256v1"
    "P-256"
  when "secp384r1"
    "P-384"
  when "secp521r1"
    "P-521"
  else
    raise "Unsupported curve: #{group.curve_name}"
  end
end

ec_key = OpenSSL::PKey::EC.new(File.read(KEY_PATH))
public_key = ec_key.public_key

group = ec_key.group
bn = public_key.to_bn

# Uncompressed point format:
# 0x04 || X || Y
hex = bn.to_s(16)
hex = "0#{hex}" if hex.length.odd?

bytes = [hex].pack("H*")

raise "Invalid EC point format" unless bytes[0].ord == 4

coordinate_size = (bytes.length - 1) / 2

x = bytes[1, coordinate_size]
y = bytes[1 + coordinate_size, coordinate_size]

jwks = {
  ISSUER => {
    keys: [
      {
        kty: "EC",
        use: "sig",
        kid: KID,
        crv: curve_name(group),
        x: b64url(x),
        y: b64url(y)
      }
    ]
  }
}

puts JSON.pretty_generate(jwks)