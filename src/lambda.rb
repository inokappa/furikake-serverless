require 'aws-sdk-kms'
require 'base64'

def decrypt_backlog_api_key
  kms = Aws::KMS::Client.new
  encrypted = Base64.decode64(ENV['ENCRYPTED_BACKLOG_API_KEY'])
  kms.decrypt(ciphertext_blob: encrypted).plaintext
end

def run(event:, context:)
  require 'furikake'
  ENV['BACKLOG_API_KEY'] = decrypt_backlog_api_key
  report = Furikake::Report.new(false, event)
  report.publish
end
