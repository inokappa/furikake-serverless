# furikake-serverless

## これなに

* [furikake](https://github.com/inokappa/furikake) を AWS Lambda で動かす為の諸々です

## 必要なもの (準備しておくもの)

* https://github.com/awslabs/aws-sam-cli
* docker と docker-compose
* S3 バケット (sam で利用します)
* KMS の Key ID
* Backlog API キー

direnv も利用出来るようにしておくとより良いと思います.

## セットアップ

### sam で利用する S3 バケットを作成する

```sh
aws s3 mb s3://your-sam-s3-bucket
```

### git clone

```sh
git clone https://github.com/inokappa/furikake-serverless.git
```

### event.json の修正

event.sample.json を修正して event.json を作成します.

```json
{
  "resources": {
    "aws": [
      "alb",
      "clb",
      "directory_service",
      "ec2",
      "elasticsearch_service",
      "kinesis",
      "lambda",
      "rds",
      "security_group",
      "vpc",
      "vpc_endpoint"
    ]
  },
  "backlog": {
    "projects": [
      {
        "space_id": "example",
        "top_level_domain": "jp",
        "wiki_id": "1234567",
        "wiki_name": "Lambda 送信テスト",
        "header": "# Test Header\n[toc]\n## Sub Header\n",
        "footer": "## Test Footer\n### Sub Footer"
      }
    ]
  }
}
```

`resources.aws` 以下のリソース名を必要に応じて, `space_id` 等を環境に応じて修正します. これは furikake の .furikake.yml と同じ内容になっていて, 単に YAML か JSON の違いです.

### sam の template.yml の生成

KMS を利用して Backlog の API キーを暗号化しますので, `make template` を実行して template.yaml を生成します.

```sh
$ make template
```

以下のように出力されるので, KMS の Key ID を API キー, 実行間隔 (任意なので, 何も指定しない場合には Enter を押下), タイムゾーン (任意なので, 何も指定しない場合には Enter を押下) を入力します.

```sh
$ make template
KMS の Key ID を入力してください:
xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxx
API キーを入力してください:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
実行間隔を分で入力してください (デフォルト 60 分):

タイムゾーンを入力してください (デフォルト Asia/Tokyo):

template.yaml created.
```

上記のように出力されると, 正常に template.yaml が生成されていると思います. 念の為, template.yaml の中身を確認してみます.

```yaml
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
      Policies:
        - ReadOnlyAccess
        - KMSDecryptPolicy:
            KeyId: xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxx
      Environment:
        Variables:
          ENCRYPTED_BACKLOG_API_KEY: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      Events:
        FurikakeSchedule:
          Type: Schedule
          Properties:
            Schedule: rate(60 minutes)
            Input: '{
  "resources": {
    "aws": [
      "alb",
...

Outputs:
  FurikakeServerless:
    Description: Serverless Furikake Lambda Function ARN.
    Value:
      Fn::GetAtt:
      - FurikakeServerless
      - Arn
```

CloudWatch Events で 60 分毎に Lambda 関数が起動するように設定されています.

```yaml
...
      Events:
        FurikakeSchedule:
          Type: Schedule
          Properties:
            Schedule: rate(60 minutes)
...
```

`Schedule: ` の値を修正することで任意の時間で Lambda 関数が起動するようにカスタマイズが可能です.

### デプロイ

`make package` と `make deploy` を実行して, Lambda 関数をデプロイします.

```sh
# packaged-template.yaml を生成して, 各種ファイルを S3 にアップロードする
make package _BUCKET_NAME=your-sam-s3-bucket
```

`make package` を実行した後, packaged-template.yaml が生成されていることを確認します.

```sh
# Lambda 関数をデプロイ
make deploy
```

以下のように出力されることを確認します.

```sh
$ make deploy

Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - FurikakeServerless
```

デプロイが完了したらしばらく待ちましょう...デフォルトで 1 時間後.

## しばらく放置しておくと

下図のように, 定期的に wiki が更新されていることを確認することが出来ると思います.

![](https://cdn-ak.f.st-hatena.com/images/fotolife/i/inokara/20181202/20181202090256.jpg)

いい感じです.

## todo

* 色々
