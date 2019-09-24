require 'aws-sdk-kms'
require 'base64'
require 'erb'

puts 'KMS の Key ID を入力してください: '
kms_key_id = gets.chop
puts 'API キーを入力してください: '
api_key = gets.chop
puts '実行間隔を分で入力してください (デフォルト 60 分): '
rate_min = gets.chop
puts 'タイムゾーンを入力してください (デフォルト Asia/Tokyo): '
timezone = gets.chop

rate_min = 60 if rate_min == ''
timezone = 'Asia/Tokyo' if timezone == ''

kms = Aws::KMS::Client.new
res = kms.encrypt(
  key_id: kms_key_id, 
  plaintext: api_key) 

encrypted_backlog_api_key = Base64.strict_encode64(res.ciphertext_blob)
input_json = File.open('event.json').read
contents =<<"EOS"
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: 'furikake-serverless'

Resources:
  FurikakeServerless:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: ./src
      Handler: lambda.run
      Runtime: ruby2.5
      Timeout: 900
      Layers:
        - !Ref FurikakeServerlessLayer
      Policies:
        - ReadOnlyAccess
        - KMSDecryptPolicy:
            KeyId: #{kms_key_id}
      Environment:
        Variables:
          ENCRYPTED_BACKLOG_API_KEY: #{encrypted_backlog_api_key}
          TZ: #{timezone}
      Events:
        FurikakeSchedule:
          Type: Schedule
          Properties:
            Schedule: rate(#{rate_min} minutes)
            Input: '#{input_json}'
  FurikakeServerlessLayer:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: FurikakeServerlessLayer
      Description: FurikakeServerless for Lambda Layer
      ContentUri: src/vendor/bundle
      RetentionPolicy: Retain
      CompatibleRuntimes:
        - ruby2.5

Outputs:
  FurikakeServerless:
    Description: Serverless Furikake Lambda Function ARN.
    Value:
      Fn::GetAtt:
      - FurikakeServerless
      - Arn
EOS

erb = ERB.new(contents, nil, '-')
File.open('template.yaml', "w") do |f|
  f.write(erb.result(binding).chomp)
  puts 'template.yaml created.'
end

# puts "Encrypted: " + encrypted_backlog_api_key
# puts "Input API Key: " + kms.decrypt(ciphertext_blob: res.ciphertext_blob).plaintext
