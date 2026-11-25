require 'minitest/autorun'

load File.expand_path('puavo-kps-fetcher', __dir__)

TEST_ISSUER = 'test-issuer'
TEST_KEY_ID = 'test-key'

describe ApprovalTokenVerifier do
  before do
    @approval_key = OpenSSL::PKey::EC.generate('prime256v1')
    @verifier = ApprovalTokenVerifier.new(TEST_ISSUER,
                                          TEST_KEY_ID => @approval_key)

    @bundle = JSON.generate('serial_number'   => 'A',
                            'organisation_id' => 'test-organisation')
    @return_public_key = 'return public key, DER'
    @claims = {
      'iss'             => TEST_ISSUER,
      'aud'             => 'puavo-kps',
      'jti'             => 'test-request',
      'iat'             => Time.now.to_i,
      'exp'             => Time.now.to_i + 60,
      'organisation_id' => 'test-organisation',
      'serial_number'   => 'A',
      'digest'          => ApprovalTokenVerifier.request_digest(
                             @bundle, @return_public_key),
      'approver'        => 'test-owner',
    }
  end

  def sign(claims, key = @approval_key, algorithm = 'ES256',
           key_id = TEST_KEY_ID)
    JWT.encode(claims, key, algorithm, 'kid' => key_id)
  end

  def refusal_code(approval_token, bundle = @bundle,
                   return_public_key = @return_public_key)
    @verifier.verify(approval_token, bundle, return_public_key)
    flunk('Expected a refusal')
  rescue Refusal => refusal
    refusal.code
  end

  it 'returns the claims of a valid approval token' do
    claims = @verifier.verify(sign(@claims), @bundle, @return_public_key)

    assert_equal 'test-owner', claims['approver']
  end

  it 'refuses an expired approval token as expired' do
    approval_token = sign(@claims.merge('exp' => Time.now.to_i - 1))

    assert_equal 'ApprovalExpired', refusal_code(approval_token)
  end

  it 'refuses an approval token without expiry' do
    approval_token = sign(@claims.reject { |claim, _| claim == 'exp' })

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'refuses an approval token signed by another key' do
    approval_token = sign(@claims, OpenSSL::PKey::EC.generate('prime256v1'))

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'refuses an approval token naming an unknown key' do
    approval_token = sign(@claims, @approval_key, 'ES256', 'unknown-key')

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'leaves a request queued when the issuer name differs' do
    approval_token = sign(@claims.merge('iss' => 'another-issuer'))

    error = assert_raises(RuntimeError) do
      @verifier.verify(approval_token, @bundle, @return_public_key)
    end
    refute_kind_of Refusal, error
  end

  it 'refuses an approval token of another issuer and key' do
    approval_token = sign(@claims.merge('iss' => 'another-issuer'),
                 OpenSSL::PKey::EC.generate('prime256v1'))

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'fails to start without approval keys' do
    Dir.mktmpdir do |key_directory|
      assert_raises(RuntimeError) do
        ApprovalTokenVerifier.read_key_directory(TEST_ISSUER, key_directory)
      end
    end
  end

  it 'refuses an approval token for another audience' do
    approval_token = sign(@claims.merge('aud' => 'another-audience'))

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'refuses HS256 keyed with the public key' do
    approval_token = sign(@claims, @approval_key.public_to_pem, 'HS256')

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'refuses an unsigned approval token' do
    approval_token = sign(@claims, nil, 'none')

    assert_equal 'ApprovalInvalid', refusal_code(approval_token)
  end

  it 'refuses a swapped return key as digest mismatch' do
    code = refusal_code(sign(@claims), @bundle, 'another return key')

    assert_equal 'DigestMismatch', code
  end

  it 'refuses a bundle of another device than approved' do
    bundle = JSON.generate('serial_number'   => 'B',
                           'organisation_id' => 'test-organisation')
    digest = ApprovalTokenVerifier.request_digest(bundle, @return_public_key)
    claims = @claims.merge('digest' => digest)

    assert_equal 'BundleMismatch', refusal_code(sign(claims), bundle)
  end

  it 'refuses a bundle that is not JSON as failed unwrap' do
    bundle = 'not JSON'
    digest = ApprovalTokenVerifier.request_digest(bundle, @return_public_key)
    claims = @claims.merge('digest' => digest)

    assert_equal 'UnwrapFailed', refusal_code(sign(claims), bundle)
  end

  it 'makes the digest of the bundle and return key digests' do
    # Made with: cat <(printf bundle | openssl dgst -sha256 -binary)
    # <(printf key | openssl dgst -sha256 -binary) | openssl dgst -sha256
    expected_digest =
      '02b531e38e717ba640eda7646da586875fcc81facc4952f65bffe688b2e741d2'

    assert_equal expected_digest,
                 ApprovalTokenVerifier.request_digest('bundle', 'key')
  end
end

describe 'answer to an approved request' do
  # Making an RSA key takes long, so the tests share one
  RETURN_KEY = OpenSSL::PKey::RSA.generate(RETURN_KEY_BITS)

  before do
    @claims = { 'organisation_id' => 'test-organisation',
                'serial_number'   => 'A' }
  end

  it 'accepts a return key of the contract' do
    public_key = parse_return_public_key(RETURN_KEY.public_to_der)

    assert_equal RETURN_KEY.n, public_key.n
  end

  it 'refuses a smaller return key' do
    small_key = OpenSSL::PKey::RSA.generate(2048)

    error = assert_raises(Refusal) do
      parse_return_public_key(small_key.public_to_der)
    end
    assert_equal 'ReturnKeyInvalid', error.code
  end

  it 'refuses a return key that is not a key' do
    error = assert_raises(Refusal) do
      parse_return_public_key('not a key')
    end
    assert_equal 'ReturnKeyInvalid', error.code
  end

  it 'refuses key data of another device than approved' do
    key_data = @claims.merge('serial_number' => 'B')

    error = assert_raises(Refusal) { check_key_data(key_data, @claims) }
    assert_equal 'BundleMismatch', error.code
  end

  it 'accepts key data of the approved device' do
    assert_nil check_key_data(@claims.merge('recovery_key' => []), @claims)
  end

  it 'encrypts the recovery key with SHA-256 OAEP' do
    result = encrypt_to_return_key('recovery key', RETURN_KEY)

    recovery_key = RETURN_KEY.decrypt(Base64.strict_decode64(result),
                                      'rsa_padding_mode' => 'oaep',
                                      'rsa_oaep_md'      => 'sha256',
                                      'rsa_mgf1_md'      => 'sha256')
    assert_equal 'recovery key', recovery_key
  end
end

describe 'unwrap of a bundle' do
  it 'refuses a bundle the station fails to unwrap' do
    original_path = ENV['PATH']
    Dir.mktmpdir do |directory|
      failing_station = File.join(directory, 'puavo-kps')
      File.write(failing_station, "#!/bin/sh\nexit 1\n")
      File.chmod(0o755, failing_station)
      ENV['PATH'] = "#{ directory }:#{ original_path }"

      error = assert_raises(Refusal) { unwrap_bundle('{}') }
      assert_equal 'UnwrapFailed', error.code
    ensure
      ENV['PATH'] = original_path
    end
  end
end
