![mongodb 3.0.1](https://img.shields.io/badge/mongodb-3.0.1-brightgreen.svg) ![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

# docker-mongodb

### Base Docker Image

[debian:wheezy](https://registry.hub.docker.com/_/debian/)

### 説明

MongoDB Dockerコンテナイメージです。

[Dockerとは？](https://docs.docker.com/)  
[Docker Command Reference](https://docs.docker.com/reference/commandline/cli/)

### 使用方法

git pull後に

    $ cd docker-mongodb

イメージ作成

    $ docker build -t tanaka0323/mongodb .

起動
    
    $ docker run -d --name <name> tanaka0323/mongodb

#### レプリケーション構成

プライマリ起動

    $ docker run -d --name <name> \
                -link <container>:alias \       # レプリケーション先セカンダリコンテナ名 複数指定可能
                -e REPLICA_SET=rsname \         # レプリカセット名
                -e DB_ADMINUSER=admin \         # 管理者名
                -e DB_ADMINPASS=password \      # 管理者パスワード
                -e CREATE_ADMINUSER=true \      # 管理者ユーザーを作成
                tanaka0323/mongodb

セカンダリ起動

    $ docker run -d --name <name> \
                -e REPLICA_SET="rsname" \    # レプリカセット名
                tanaka0323/mongodb

#### シャードクラスタ構成

コンフィグサーバー起動

    $ docker run -d --name <name> \
                -e CONFIG_SERVER=true \      # コンフィグサーバーとして起動
                tanaka0323/mongodb

ルーター起動

    $ docker run -d --name <name> \
                -link \
                    <container>:config1 \       # ルーティングするコンフィグサーバーコンテナ名 頭にconfigと付いた連番のalias名を指定すること 複数指定可
                    <container>:repl1 \         # シャーディングするレプリカセットプライマリコンテナ名 頭にreplと付いた連番のalias名を指定すること 複数指定可
                -e ROUTER=true \                # ルーターとして起動
                -e DB_ADMINUSER=admin \         # 管理者名
                -e DB_ADMINPASS=password \      # 管理者パスワード
                -e CREATE_ADMIN_USER=true \     # 管理者ユーザーを作成
                tanaka0323/mongodb

### SSL認証鍵によるサーバー相互認証

デフォルトではSSL認証は無効になっていますが、有効にするにはルーター、コンフィグサーバー、シャードサーバー全てに以下の設定を行って下さい。

    $ docker run -d --name <name> \
                -e AUTH=true \              # 認証機能有効
                -e DB_ADMINUSER=admin       # 認証する管理者名
                -e DB_ADMINPASS=password    # 認証する管理者パスワード
                <tag>/mongodb

### 環境変数

- <code>DB_ADMINUSER</code>管理者名
- <code>DB_ADMINPASS</code>管理者パスワード
- <code>CREATE_ADMINUSER</code>管理者ユーザーを作成 基本的にはレプリカセットのプライマリ、ルーターのみに設定します。
- <code>AUTH</code>認証機能 true or false
- <code>JOURNAL</code>ジャーナル機能 true or false
- <code>REPLICA_SET</code>レプリカセット名
- <code>CONFIG_SERVER</code>コンフィグサーバーとして起動  true or false
- <code>ROUTER</code>ルーターとして起動  true or false
- <code>REPLICATION_DELAY</code>自動レプリケーション遅延時間 デフォルト20秒
- <code>SHARDING_DELAY</code>自動シャーディング遅延時間 デフォルト40秒

### Figでの使用方法

[Figとは？](http://www.fig.sh/)  

[設定ファイル記述例](https://bitbucket.org/tanaka0323/fig-examples)

### License

The MIT License
Copyright (c) 2015 Daisuke Tanaka

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。