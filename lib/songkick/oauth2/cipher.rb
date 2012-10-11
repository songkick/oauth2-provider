module Songkick
  module OAuth2
    
    #     +---------+                           +--------+
    #     | Message +---------+                 | Secret |
    #     +---------+         |                 +---+----+
    #                         |                     |
    #                         |   +-----------+     |     +-----------+
    #                         |   | PBKDF2(1) |<----+---->| PBKDF2(2) |
    #                         |   +-----+-----+           +-----+-----+
    #                         |         |                       |
    #                         V         V                       |
    #     +-----------+     +-------------+                     |
    #     | Random IV +---->| AES-256-CBC |                     |
    #     +-----+-----+     +-----+-------+                     |
    #           |                 |                             |
    #           V                 V                             V
    #     +-----------+-------------------+               +-----------+
    #     |     IV    |     AES output    +-------------->| HMAC-SHA1 |
    #     +-----+-----+-----------+-------+               +-----+-----+
    #           |                 |                             |
    #           V                 V                             V
    #     +-----------+-----------------------------------+-----------+
    #     |     IV    |              Payload              |    Tag    |
    #     +-----------+-----------------+-----------------+-----------+
    #                                   |
    #                                   V
    #                               +---------+
    #                               | Base-64 |
    #                               +---+-----+
    #                                   |
    #                                   V
    #                             +------------+
    #                             | Ciphertext |
    #                             +------------+
    #
    class Cipher
      CIPHER_MODE = 'aes-256-cbc'
      KDF_HASH    = :sha1
      KDF_WORK    = 100
      KEY_SIZE    = 256
      IV_SIZE     = 128
      HMAC_TYPE   = 'sha1'
      HMAC_SIZE   = 160
      UUID        = 'c7667ed4-9bf7-4495-bfa1-866291e9ce2a'
      
      def initialize(secret)
        @secret = secret
      end
      
      def encrypt(plaintext)
        keys   = derive_keys
        iv     = OAuth2.random_string(IV_SIZE, 16)
        cipher = create_cipher(:encrypt, keys.first, iv)
        
        ciphertext = cipher.update(plaintext) + cipher.final
        result = iv + bin2hex(ciphertext)
        
        hash = OpenSSL::Digest.new(HMAC_TYPE)
        tag  = OpenSSL::HMAC.hexdigest(hash, keys.last, result)
        
        hex2base64url(result + tag)
      end
      
      def decrypt(ciphertext)
        ciphertext = base64url2hex(ciphertext)
        
        keys     = derive_keys
        iv       = ciphertext[0...(IV_SIZE/4)]
        payload  = ciphertext[(IV_SIZE/4)...(ciphertext.size - HMAC_SIZE/4)]
        tag      = ciphertext[(ciphertext.size - HMAC_SIZE/4)..-1]
        decipher = create_cipher(:decrypt, keys.first, iv)
        
        hash     = OpenSSL::Digest.new(HMAC_TYPE)
        check    = OpenSSL::HMAC.hexdigest(hash, keys.last, iv + payload)
        expected = OpenSSL::HMAC.hexdigest(hash, UUID, tag)
        actual   = OpenSSL::HMAC.hexdigest(hash, UUID, check)
        
        payload   = hex2bin(payload)
        plaintext = decipher.update(payload) + decipher.final
        
        return nil unless expected == actual
        
        plaintext
        
      rescue OpenSSL::Cipher::CipherError
        nil
      end
      
    private
      
      def create_cipher(type, key, iv)
        cipher = OpenSSL::Cipher.new(CIPHER_MODE)
        cipher.__send__(type)
        cipher.key = key
        cipher.iv  = hex2bin(iv)
        cipher
      end
      
      def derive_keys
        params = {
          :password       => @secret,
          :salt           => UUID,
          :key_length     => KEY_SIZE/16,
          :hash_function  => KDF_HASH
        }
        
        [1, 2].map do |i|
          PBKDF2.new(params.merge(:iterations => i * KDF_WORK)).hex_string
        end
      end
      
      def bin2hex(string)
        string.bytes.map { |b| b.to_s(16).rjust(2, '0') } * ''
      end
      
      def hex2bin(string)
        string.scan(/../).map { |b| b.to_i(16) }.pack('C*')
      end
      
      def base64url2hex(string)
        string = string.
            gsub(/\-/, '+').
            gsub(/\_/, '/')
        
        string += '=' while string.size % 4 != 0
        bin2hex(Base64.decode64(string))
      end
      
      def hex2base64url(string)
        Base64.encode64(hex2bin(string)).
            gsub(/\s/, '').
            gsub(/\=/, '').
            gsub(/\+/, '-').
            gsub(/\//, '_')
      end
    end
    
  end
end

