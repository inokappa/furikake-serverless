# furikake-serverless

## これなに

* [furikake](https://github.com/inokappa/furikake) を AWS Lambda で動かす為の諸々です

## 必要なもの (準備しておくもの)

* https://github.com/awslabs/aws-sam-cli
* Docker
* S3 バケット
* KMS の Key ID
* Backlog API キー

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

event.sample.json を修正して event.json を作成する.

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

`space_id` 等を環境に応じて修正する.

### sam の template.yml の生成

`make template` を実行して template.yaml を生成する.

```sh
$ make template
```

以下のように出力されるので, KMS の Key ID を API キーを入力する.

```sh
$ make template
KMS の Key ID を入力してください:
xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxx
API キーを入力してください:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
template.yaml created.
```

### デプロイ

`make package` と `make deploy` を実行して, Lambda 関数をデプロイする.

```sh
# packaged-template.yaml を生成して, 各種ファイルを S3 にアップロードする
make package _BUCKET_NAME=your-sam-s3-bucket

# Lambda 関数をデプロイ
make deploy
```

## todo

* 色々