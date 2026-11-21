# AI Snip

AI Snipは [Snip](/ja/usage/snip) に画像解析機能を追加します。スニップを撮影したあと、サムネイルを右クリックすると、テキスト抽出、翻訳、オブジェクト検出、被写体へのトリミングができます。

AI機能はGoogleのGemini APIを使用します。ご自身のAPIキーを追加するまでオフです。

## セットアップ

1. [Google AI Studio](https://aistudio.google.com/apikey) で無料のキーを取得する
2. **ZoomacIt 設定 → 一般** を開く
3. **Enable AI (requires Gemini API key)** をオンにする
4. **Gemini API Key** にキーを貼り付ける
5. モデルを選ぶ（デフォルトは **Gemini Flash (Latest)**）

AIを有効にしてキーを設定するまで、AIのメニュー項目はグレーアウトされています。

## 使い方

1. **⌃6**（またはファイル保存の場合 **⌃⇧6**）を押し、ドラッグで領域を選択
2. スニップのサムネイルが表示される
3. サムネイルを**右クリック**
4. メニューからアクションを選ぶ

## アクション

| アクション | 内容 | 結果 |
|---|---|---|
| Extract Text | スニップ内の文字をすべて読み取る | テキストがクリップボードにコピーされる |
| Translate Text | 文字を読み取って英語に翻訳する | 翻訳がクリップボードにコピーされる |
| Search Text | 文字を読み取り、Googleで検索する | 検索結果がブラウザで開く |
| Image Search | Google Lensを開く | 画像がコピーされるので、Lensに貼り付ける |
| Find Objects | オブジェクトとその位置を検出する | オブジェクト一覧（バウンディングボックス付きJSON）がクリップボードにコピーされる |
| Smart Reframe | 主な被写体を見つけてトリミングする | トリミングした画像がクリップボードにコピーされる |
| Copy Image | スニップを画像としてコピーする | 画像がコピーされ、サムネイルが閉じる |

リクエストの実行中は **Analyzing...** のダイアログが表示され、そのあと結果の短い確認が表示されます。

## 設定

| 設定 | 説明 | デフォルト |
|---|---|---|
| Enable AI | AIのメニュー項目をオンにする | オフ |
| Gemini API Key | Google AI Studioで取得したキー | 空 |
| Model | 使用するGeminiモデル | Gemini Flash (Latest) |

選べるモデル: Gemini Flash (Latest)、Gemini 2.0 Flash、Gemini 2.0 Flash-Lite、Gemini 2.5 Flash、Gemini 2.5 Pro。

## プライバシー

AIアクションを実行すると、ZoomacItはそのスニップをあなたのキーでGoogleのGemini APIに送信します。アクションを選ぶまでは何も送信されません。コピーまたは保存するだけのスニップがアップロードされることはありません。

Image SearchはGeminiを呼び出しません。スニップをコピーしてGoogle Lensを開くので、貼り付けはご自身で行います。

## レート制限

Geminiの無料枠には利用制限があります。選択したモデルがレート制限エラーを返した場合、ZoomacItはGemini 2.0 Flash-Liteで1回だけ再試行します。それも制限されている場合は「Rate limited」と表示されるので、1分ほど待ってからもう一度お試しください。
