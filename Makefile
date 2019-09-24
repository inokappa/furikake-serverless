default: ## ヘルプを表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

depend: ## 依存パッケージの導入
	@cd src && bundle install --path vendor/bundle && cd ..

template: ## template.yaml を生成
	@docker-compose run write-template-yaml

invoke: ## ローカルで関数を実行する
	@sam local invoke FurikakeServerless -e event.json

package: ## 依存パッケージをアップロードする (_BUCKET_NAME= でバケット名を指定する)
	@cd src && \
		bundle install --path vendor/bundle && \
		cd .. && \
		sam package --template-file template.yaml \
		  --output-template-file packaged-template.yaml \
		  --s3-bucket ${_BUCKET_NAME}

deploy: ## Lambda 関数をデプロイする
	@sam deploy --template-file packaged-template.yaml \
		  --stack-name FurikakeServerless \
		  --capabilities CAPABILITY_IAM
