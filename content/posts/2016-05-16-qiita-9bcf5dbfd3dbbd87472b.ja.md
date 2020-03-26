+++ 
date = "2016-05-16"
title = "wercker の新機能 Wercker Workflows を試す"
slug = "qiita-9bcf5dbfd3dbbd87472b" 
tags = ["Rails","wercker"]
categories = []
+++

*この記事は[Qiita](https://qiita.com/dtan4/items/9bcf5dbfd3dbbd87472b)の記事をエクスポートしたものです。内容が古くなっている可能性があります。*

プライベートリポジトリの CI 無料でお馴染みの [wercker](http://wercker.com/) が、先日ワークフロー機能 __[Wercker Workflows](http://wercker.com/workflows/)__ をリリースしました。

とりあえず、以下の公式デモ動画を観れば何ができるのかわかると思います。

ブログ記事 :point_right: __[Introducing Wercker Workflows](http://blog.wercker.com/2016/05/09/Introducing-Wercker-Workflows.html)__
デモ動画 :point_right: __[Wercker Workflows - YouTube](https://www.youtube.com/watch?time_continue=1&v=-D7CmhjZvXY)__

## Wercker Workflows とは
いわゆるワークフロー機能というやつで、1つの CI プロセスを複数のパイプラインに分割して組み合わせる機能です。Jenkins とか、最近だと [Concourse CI](https://concourse.ci/) でお馴染みの機能です。

パイプラインは従来の `build`, `deploy` に相当するもので、1つの CI プロセス内におけるタスクの分割単位となります。従来は `build`, `deploy` の2つしか記述できなかったところ、`test` や `push-dev` のように複数種類のパイプラインを記述できるようになったのが今回の Workflows です。

以下の例では、`Build`, `Tests`, `Push to registry`, `Notify Scheduler` の4つのパイプラインを直列に実行しています。これだけだと従来の wercker とあまり変わりません。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-1.png)

_image from: http://wercker.com/workflows/_

Workflows では、複数のパイプラインを__並列に__実行することができます。以下の例は、ビルド後に開発用 (dev) イメージの push & deploy と本番用 (release) イメージの push & deploy を並列に実行しています。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-2.png)

_image from: http://wercker.com/workflows/_

それぞれのタスクは、__個別に abort & restart することが可能__です。例えば `build` -> `test1` -> `test2` の CI プロセスが組まれている場合、従来だと `test2` だけやり直したい時も最初の `build` から restart させる必要がありました。Workflows では、以下のように `test2` だけやり直すことが可能となります。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-3.png)

_image from: http://wercker.com/workflows/_

この Workflows、プライベートリポジトリに対しても__無料__で使うことができます。相変わらず太っ腹ですね…

## Workflows を使ってみよう
実際に Rails アプリの CI を Wercker Workflows を使って実行してみましょう。

今回のチュートリアルに用いるサンプルリポジトリです: https://github.com/dtan4/rails-wercker-workflows
wercker ページです: https://app.wercker.com/#applications/57397bbed99505465708deb7 [![wercker status](https://app.wercker.com/status/bfbb4e09d3c9a7e7c7b43a04971e2db1/s/master "wercker status")](https://app.wercker.com/project/bykey/bfbb4e09d3c9a7e7c7b43a04971e2db1)

### `wercker.yml`
いきなりですが、`wercker.yml` は以下のようになります。

```yaml
box:
  id: quay.io/dtan4/rails-test-base
  tag: latest
  registry: quay.io

services:
  - postgres:9.4

build:
  steps:
    - bundle-install

rspec-models:
  steps:
    - bundle-install
    - script:
        name: Set POSTGRES_USER
        code: export POSTGRES_USER=postgres
    - script:
        name: Prepare database
        code: bundle exec rake db:test:prepare
    - script:
        name: Run RSpec
        code: bundle exec rspec spec/models

rspec-controllers:
  steps:
    - bundle-install
    - script:
        name: Set POSTGRES_USER
        code: export POSTGRES_USER=postgres
    - script:
        name: Prepare database
        code: bundle exec rake db:test:prepare
    - script:
        name: Run RSpec
        code: bundle exec rspec spec/controllers

rspec-features:
  steps:
    - bundle-install
    - script:
        name: Set POSTGRES_USER
        code: export POSTGRES_USER=postgres
    - script:
        name: Prepare database
        code: bundle exec rake db:test:prepare
    - script:
        name: Run RSpec
        code: bundle exec rspec spec/features
```

ベースの Docker image として、[quay.io/dtan4/rails-test-base:latest](https://quay.io/repository/dtan4/rails-test-base) を使っています。このイメージは公式の `ruby:2.3.0` イメージを元に Node.js や PhantomJS をインストールしたものです。`Dockerfile` はリポジトリルートに置いてあるやつです: https://github.com/dtan4/rails-wercker-workflows/blob/master/Dockerfile。
ベースイメージを `ruby:2.3.0` にして都度 `apt-get install` するようにしてもよいのですが、`apt-get install` の結果はキャッシュされず毎回走ることになるので、時間短縮のためにキャッシュの効く Docker image に前もって含めるようにしています。

データベースは PostgreSQL を使うので、`services` に `postgres:9.4` を指定して PostgreSQL 9.4 のコンテナを立ち上げるようにしています。Elasticsearch とか Redis も必要であれば指定できます。
`services` のコンテナは__各パイプラインにつきそれぞれ1個ずつ立ち上がる__ので、パイプライン間でデータベースアクセスの競合が起こるようなことはありません。便利。

この `wercker.yml` では、以下の4つのパイプラインを定義しています。

- `build`: GitHub push を受けて最初に実行されるパイプライン
- `rspec-models`: `spec/models` のテスト
- `rspec-controllers`: `spec/controllers` のテスト
- `rspec-features`: `spec/features` のテスト

:warning: 注意したいのは、テストのパイプラインそれぞれが `bundle install` を実行している点です。最初の `build` パイプラインで `bundle install` を実行し、その結果をテストのパイプラインで利用すればいいと思われるかもしれません。しかし、どうやらキャッシュディレクトリである `WERCKER_CACHE_DIR` は各パイプラインで独立に設定されているらしく、テストのパイプラインで `build` パイプラインの結果を利用することができませんでした。
なので、__初期化処理の類は各パイプラインでそれぞれ実行する必要があります__。おそらく、`git clone` したコードベース上で各パイプラインの Docker コンテナが走っているだけなんだと思います。

上の例だと build のあとに push が走っているので、別にパイプライン間共有のディレクトリがあるんだと思いますが…

### wercker の設定
まずアカウントを取得し、https://app.wercker.com/#applications/create からリポジトリを登録します。

次に、アプリの画面で "Manage Workflows" をクリックし
![image](/images/qiita-9bcf5dbfd3dbbd87472b-4.png)

ワークフローの登録と連携を行うページに飛びます。Pipelines には、デフォルトで GitHub/Bitbucket push がトリガーとなる `build` パイプラインが設定されています。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-5.png)

"Add new pipelines" からパイプラインを登録します。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-6.png)

"Name" には wercker 上で表示されるパイプライン名、"YML Pipeline name" には `wercker.yml` に記述したパイプライン名を入力します。
"Hook type" はこのパイプラインのトリガーを指定します。以下の2種類から選べます。

- `Default`: 他のパイプラインの成功をトリガーにする（従来の `deploy`）
- `Git push`: GitHub/Bitbucket への push をトリガーにする（従来の `build`）

"Create" するとパイプラインの個別設定ができます。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-7.png)

パイプライン独自の環境変数を設定できたりします。
また、"Report to SCM" にチェックを入れておくと GitHub の Pull Request 画面にパイプラインの実行結果を反映できます。イメージこんな感じです。壮観。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-8.png)


全部登録するとこんな感じになります。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-9.png)

次に、このパイプラインを組み合わせてワークフローを構築します。`build` の後ろにある "+" をクリックすると、後に続くパイプラインを追加できます。特定のブランチのみ実行するようにもできます。
なお、1つのワークフロー上では同じパイプラインは1回しか使えません。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-10.png)

全部登録するとこうなります。テストのパイプラインは並列実行するようにしました。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-11.png)

これで wercker の設定は終わりです。

### テスト実行
`git push` すると CI が走り始めます。こんな感じでブラウザに進捗が表示されます。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-12.png)

:warning: 並列に記述してあるパイプラインは、同時にスタートするようになっていません。従来のビルドと同じように各パイプラインもキューに突っ込まれ、適宜デキューして実行しているようです。

各パイプラインをクリックすれば、そのパイプラインの詳しい進捗を確認できます。この画面は従来の wercker と同じですね。このページからパイプラインの abort や restart を行うことができます。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-13.png)

_https://app.wercker.com/#dtan4/rails-wercker-workflows/rspec-controllers/57398ba39779f5075802a86_

全部のパイプラインが成功すればこうなり、

![image](/images/qiita-9bcf5dbfd3dbbd87472b-14.png)

どれか一つ失敗すればこうなります。この `rspec-models` パイプラインが通信エラーのように気まぐれで失敗していた場合は、これだけ個別に再実行することができます。

![image](/images/qiita-9bcf5dbfd3dbbd87472b-15.png)

トータルの実行時間がひと目でわからないのは厳しいですね…

### 並列実行の効果
今回はテストを3分割し並列に走らせましたが、直列に実行した場合に比べ1分程度早く終了することが確認できました (1m23s vs. 2min30s)。前述したようにパイプラインの実行タイミングに差があるので、思ったほど実行時間が短くなるわけではありません。しかし、コンテナレベルで環境が分離されるので他の同時実行しているテストの影響を受けにくいこと、各テストを個別にリスタート可能になるといった利点があるので、前向きに Workflows による並列実行を取り入れていっても良さそうです。

## おわりに
Wercker Workflows の紹介と実際に Rails アプリの CI に使ってみる例を紹介しました。
wercker 社は[今年の2月に資金調達してます](http://thebridge.jp/2016/02/wercker-raises-4-5-million-open-sources-its-command-line-tool)し、[有料の VPC プラン](http://wercker.com/pricing/)も作られるなど活動が盛んになってきています。今後の進化にも期待したいところです。

## REF
- [wercker - docs - Workflows](http://devcenter.wercker.com/docs/workflows/index.html)
