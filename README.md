# 概要
terraformにおいて活用できそうなモジュールを格納していく。<br>
モジュールは、サービス単位であったりネットワーク単位で管理する。<br>
terraform-docsでREADMEを作成し、変更時にはタグ付けも行う。

## terraform-docsについて
モジュールに変更があった場合は以下のコマンドを実行し、モジュール内のREADMEの更新を行うこと

```
./create-docs.sh
```

## git pushについて
呼び出すterraform側でバージョン指定を行うため、タグ付けを行って管理する。<br>
変更時には以下のコマンドを実行し、タグによる管理を行う。

```
git add xxx.tf
git commit -m "update xxx.tf"
git push origin branch
git tag -a "v0.0.1" -m "update xxx module"
git push --follow-tags
```