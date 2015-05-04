![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

docker-mongodb
=====================

Base Docker Image
--------------------------

[dtanakax/debianjp:wheezy](https://registry.hub.docker.com/u/dtanakax/debianjp/)

説明
--------------------------

MongoDB Dockerコンテナ作成設定

使用方法
--------------------------

起動
    
    $ docker run -d --name <name> dtanakax/mongodb

レプリケーション構成
--------------------------

プライマリ起動

    $ docker run -d --name <name> \
                -link <container>:alias \       # レプリケーション先セカンダリコンテナ名 複数指定可能
                -e REPLICA_SET=rsname \         # レプリカセット名
                -e DB_ADMINUSER=admin \         # 管理者名
                -e DB_ADMINPASS=password \      # 管理者パスワード
                -e CREATE_ADMINUSER=true \      # 管理者ユーザーを作成
                dtanakax/mongodb

セカンダリ起動

    $ docker run -d --name <name> \
                -e REPLICA_SET="rsname" \    # レプリカセット名
                dtanakax/mongodb

シャードクラスタ構成
--------------------------

コンフィグサーバー起動

    $ docker run -d --name <name> \
                -e CONFIG_SERVER=true \      # コンフィグサーバーとして起動
                dtanakax/mongodb

ルーター起動

    $ docker run -d --name <name> \
                -link \
                    <container>:config1 \       # ルーティングするコンフィグサーバーコンテナ名 頭にconfigと付いた連番のalias名を指定すること 複数指定可
                    <container>:repl1 \         # シャーディングするレプリカセットプライマリコンテナ名 頭にreplと付いた連番のalias名を指定すること 複数指定可
                -e ROUTER=true \                # ルーターとして起動
                -e DB_ADMINUSER=admin \         # 管理者名
                -e DB_ADMINPASS=password \      # 管理者パスワード
                -e CREATE_ADMIN_USER=true \     # 管理者ユーザーを作成
                dtanakax/mongodb

環境変数
--------------------------

- `DB_ADMINUSER` 管理者名
- `DB_ADMINPASS` 管理者パスワード
- `CREATE_ADMINUSER` 管理者ユーザーを作成 基本的にはレプリカセットのプライマリ、ルーターのみに設定します。
- `CONFIG_SERVER` コンフィグサーバーとして起動  true or false
- `ROUTER` ルーターとして起動  true or false
- `REPLICATION_DELAY` 自動レプリケーション遅延時間 デフォルト30秒
- `SHARDING_DELAY` 自動シャーディング遅延時間 デフォルト50秒
- `OPTIONS` MongoDB起動オプション [参考URL](http://docs.mongodb.org/manual/reference/program/mongod/)

License
--------------------------

The MIT License
Copyright (c) 2015 Daisuke Tanaka

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。

The MIT License
Copyright (c) 2015 Daisuke Tanaka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.