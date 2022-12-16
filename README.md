# Rust CLI Template with clap

This is a private template repository, when I create a new CLI project, I use this template.


## サンプル記事です。

こんにちは、[@ekusiadadus](https://qiita.com/ekusiadadus)です。
CLI ツール作っていますか？
CLI ツールを Rust で作るときに、毎回環境を整えるのが面倒だったので、テンプレを作りました。
今回はそのテンプレを使って、簡易的な CLI ツールを Rust で爆速で作ってみます。

テンプレートはこちらです。

https://github.com/ekusiadadus/rust-cli-template

今回作るコマンドラインツールはこちらです。

https://github.com/ekusiadadus/dirsearch

[https://crates.io/](https://crates.io/) に登録して配布した CLI ツールです。

https://crates.io/crates/dirsearch

`cargo install dirsearch`でインストールできます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/648e1d14-90a0-8b0a-6b53-a8ee58fb4a0f.png)

## テンプレを使って CLI ツールを作る

今回は、よくあるディレクトリ配下に存在するフォルダ、ファイルの数とその大きさを表示する CLI ツールを爆速で作ってみます。

### テンプレをクローンする

まずは、テンプレをクローンします。

```bash
git clone https://github.com/ekusiadadus/rust-cli-template.git
```

### `cargo run` で実行してみる

テンプレを使うには、テンプレのディレクトリに移動して、`cargo run`を実行します。

```bash
cd rust-cli-template
cargo run
```

うまくいけば、こんな感じで、`rust-cli-template`という名前の CLI ツールが実行されます。

既にこの段階で、`cargo run` で CLI ツールが実行できる環境が整っています。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/65ca595c-f0cc-b421-b0df-663a8d440352.png)

### (余談) mold + cargo watch を使う

mold + cargo watch は使わなくてもいいですが、以下の点で便利です。

- ホットリロードされる開発環境
- ビルドが速くなる

ここら辺は、参考記事を貼っておくのでもしよかったら使ってみてください。

https://keens.github.io/blog/2021/12/20/moldwotsukautorustnobirudogahayakunaru/

https://qiita.com/kyamamoto9120/items/2081bc44c6c987b9ec29

今回の場合、`cargo watch -s 'mold -run cargo run'` でホットリロードできる環境にしています。
Makefile も載せてあるので、`make watch` で動きます。

保存すると自動的にビルドされて、実行されます。

![build-with-mold.gif](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/5179de33-882f-2110-d1e8-da616f4c3c67.gif)

### ディレクトリ配下のファイル、フォルダの数と大きさを表示する

walkDir を使って、ディレクトリ配下のファイル、フォルダの数と大きさを表示するようにします。

#### walkDir をインストールする

[walkdir](https://docs.rs/walkdir/latest/walkdir/)をつかいます。

```bash
cargo add walkdir
```

walkDir を使うには、`use walkdir::WalkDir;` を追加します。

#### ディレクトリ配下のファイル、フォルダを取得する

```rust
use walkdir::WalkDir;

fn main() {
    for entry in WalkDir::new(".") {
        let entry = entry.unwrap();
        println!("{}", entry.path().display());
    }
}
```

`cargo run` で実行すると、ディレクトリ配下のファイル、フォルダが表示されます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/0307ea38-4f5a-e3ad-83c6-54b07b12ccc8.png)

#### ディレクトリ配下のファイル、フォルダの数と大きさを表示する

ディレクトリ配下のファイルと、フォルダを走査して、ファイルの数と大きさを表示するようにします。
walkdir を使うと非常に簡単にファイルとフォルダを走査できます。

```rust
use walkdir::WalkDir;
const DIR: &str = "./";

fn main() {
    let mut size: u64 = 0;
    let mut count: u64 = 0;

    for entry in WalkDir::new(DIR).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_file() {
            size += path.metadata().unwrap().len();
            count += 1;
        }
        println!("{}", entry.path().display());
    }

    println!("{} files, {} bytes", count, size);
}
```

実際に`cargo run` で走らせてみるとこんな感じ。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/665eefaa-11e4-3914-b0f8-b7b67b69c1ab.png)

現在のディレクトリ配下には、626 個のファイルが存在して、総合で`304742935 bytes`の大きさになることがわかります。

#### (余談 2) ファイルサイズを Rust でいい感じに表示するには...

ファイルサイズを Rust でいい感じに表示するには、[file_size](https://crates.io/crates/file-size)を使います。

```txt
use file_size::fit_4;

assert_eq!(&fit_4(999), "999");
assert_eq!(&fit_4(12345), "12K");
assert_eq!(&fit_4(999_999), "1.0M");
assert_eq!(&fit_4(7_155_456_789_012), "7.2T");
```

こんな感じで、いい感じにファイルサイズを表示してくれるクレートです。

```bash
println!("{} files, {} bytes", count, fit_4(size));
```

使ってみるとこんな感じ。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/47abfd56-1992-a2e1-e420-1829802ba887.png)

ええやん。

#### ディレクトリ配下のファイルで上位 N 件を持ってくる

ディレクトリ配下のファイルで上位 N 件を持ってくるようにします。
あと `main` が大きくなってきたので、関数に切り出します。

```rust
fn get_dir_size(dir: &str) -> Result<(), Box<dyn Error>> {
    let mut size: u64 = 0;
    let mut count: u64 = 0;
    let mut tops: Vec<Entry> = Vec::with_capacity(NUM + 1);
    let mut min_tops: u64 = 0;

    for entry in WalkDir::new(dir).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_file() {
            let t = path.metadata().unwrap().len();
            if t > min_tops {
                tops.push(Entry {
                    path: path.to_str().unwrap().to_string(),
                    size: t,
                });
                tops.sort_by(|a, b| b.size.cmp(&a.size));
                tops.truncate(NUM);
                min_tops = tops.last().unwrap().size;
            }
            size += path.metadata().unwrap().len();
            count += 1;
        }
    }

    println!("{} files, {} bytes", count, fit_4(size));
    println!("{} largest files:", NUM);
    println!("{} | {}", "Size", "Path");
    for t in tops {
        println!("{} | {}", fit_4(t.size), t.path);
    }

    Ok(())
}
```

実行するとこんな感じ。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/f345fd37-30a3-74d2-3829-ae472efd0a83.png)

#### ディレクトリ配下のファイルで上位 N 件を持ってくる (並列処理)

#### Clap を使って、コマンドラインツールにする

clap v4 を使って、コマンドラインツールにします。
v4 は、v3 とはかなり違うので、[clap v4 のドキュメント](https://docs.rs/clap/4.0.0-beta.2/clap/)を見ながら進めましょう。

```rust
use clap::Parser;

#[derive(Parser)]
#[command(author, version, about, long_about = None)] // Read from `Cargo.toml`
struct Cli {
    #[arg(long)]
    number: usize,
}

fn main() {
    let cli = Cli::parse();
    let num = cli.number;
    let dir = DIR;

    if num == 0 {
        println!("Number of files to show must be greater than 0");
        return;
    }

    get_dir_size(dir, num).unwrap();
}

```

実際に実行するとこんな感じになります。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/85531089-9844-45ef-28c3-1e695c2c52ae.png)

`--number` argument を忘れると怒られます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/171dbe0a-83b1-78e0-516e-8e34e99f70ba.png)

例えば、上位 100 件を表示するには、`--number 100`とします。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/03e43d57-d499-9549-dc5d-334a62d76d20.png)

デフォルトで `--help` が使えるようになっています。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/40c20884-6fde-a0d1-2f4c-8c1c7903bcbb.png)

`Cargo.toml` に書いた情報が、`--help` で表示されます。

```toml
[package]
name = "dirsearch"
version = "0.1.0"
edition = "2021"
license = "MIT OR Apache-2.0"
description = "🌸 Rust CLI Template using clap v4 🌸"
readme = "README.md"
homepage = "https://github.com/ekusiadadus/dirsearch"
repository = "https://github.com/ekusiadadus/dirsearch"
keywords = ["cli", "Japan", "Rust"]
categories = ["command-line-utilities"]

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
clap = { version = "4.0.29", features = ["derive"] }
file-size = "1.0.3"
walkdir = "2.3.2"
```

#### dirsearch を cretes.io に登録して配布する

[https://crates.io/](https://crates.io/)

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/fe021086-ad45-3dad-d0fa-dfab359ca57d.png)

コマンドラインツールができたので、実際に `cargo install dirsearch` できるように[https://crates.io/](https://crates.io/)に登録します。

`cargo release --dry-run` で、リリースの準備をします。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/77454e41-68a5-60c9-1d65-f4b6a5db8d47.png)

成功したら、実際にローカルでインストールして動かしてみましょう。

`cargo install --path .` で、ローカルにインストールできます。
`dirsearch` で、コマンドラインツールが使えるようになります。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/1efbefeb-8bab-e2dd-c375-205c9adff7d8.png)

各コマンドが実際に動く確認します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/9a4e2e3a-2a3e-4bc2-1f1d-02eff6ac0243.png)

ちゃんと動いていそう。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/e09b10d3-59b5-765b-5842-47472dd9c13e.png)

実際に動いているので、配布します。
`cargo publish` で、[https://crates.io/](https://crates.io/)に登録できます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/efa72788-5b91-0d1b-81b2-cc9adf04e943.png)

登録できたことが確認できました。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/19c59fe8-baa9-a4c5-8daf-b8a4aa72e9c8.png)

これで、どこからでも`cargo install dirsearch`できますね！

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/905557/648e1d14-90a0-8b0a-6b53-a8ee58fb4a0f.png)

## まとめ

Rust でコマンドラインツールを爆速で作る環境を構築しよう 2022 年版ということで、いかがだったでしょうか？

https://crates.io/crates/dirsearch

[テンプレ](https://github.com/ekusiadadus/rust-cli-template)を使ってを配布するまでに 1 時間かからず行えました！

https://github.com/ekusiadadus/dirsearch

上が今回実際に配布したコマンドラインツールのリポジトリです。
めちゃくちゃかんたんですよね！

https://github.com/ekusiadadus/rust-cli-template

他にも、Rust で作ったコマンドラインツールを[テンプレ](https://github.com/ekusiadadus/rust-cli-template)から作っています。

https://qiita.com/ekusiadadus/items/5f15369a91fe01a66752

https://github.com/ekusiadadus/samuraicup

https://github.com/ekusiadadus/twisort

ここら辺は、Twitter API を使っているので完全に自分用ですが、Rust でコマンドラインツールを作るのはとても楽しいですね！
clap v4 からかなり仕様が変わったので、結構 clap になれるのが大変かもしれませんが、テンプレを使って爆速で作れるので、ぜひ試してみてください！
