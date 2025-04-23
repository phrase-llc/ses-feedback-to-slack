# SES フィードバック通知 to Slack (SNS / Lambda)

Amazon SES から発生する **バウンス（送信失敗）** および **苦情（Complaint）** 通知を  
Slack に自動で送信する AWS Lambda 関数です。
バウンスと苦情以外の通知はエラーになり、通知されません。
AWS SAM によって構築されています。

---

## 📌 機能概要

- SES の通知（SNS 経由）を受信
- バウンスと苦情の通知を判別
- Slack の Incoming Webhook を使って通知を送信
- SAM CLI によるローカル実行・テストが可能

---

## 🧱 構成技術

| 技術                     | 用途              |
|------------------------|-----------------|
| AWS Lambda (Ruby)      | メイン処理ロジック       |
| AWS SNS                | SES の通知中継       |
| Slack Incoming Webhook | 通知送信先           |
| AWS SAM                | デプロイ・ローカル実行・テスト |
| test-unit + mocha      | テストフレームワーク      |

---

## 🚀 デプロイ手順

### 1. 環境変数の設定

#### 開発環境

- `mv .env.sample.json .env.json` で `.env.json` を作成
- `.env.json` に Slack の Incoming Webhook URL を設定

```json
{
  "Parameters": {
    "SLACK_WEBHOOK_URL": "https://hooks.slack.com/services/XXXX/YYYY/ZZZZ"
  }
}
```

#### 本番環境
デプロイ成功後に Lambda 本番環境の環境変数に以下を設定

| 変数名               | 説明                           |
|-------------------|------------------------------|
| SLACK_WEBHOOK_URL | Slack の Incoming Webhook URL |

> `.env.json` はローカル実行専用、本番には適用されません。

### IAMユーザーの作成、ポリシー設定とプロファイルの設定（初回のみ）
- IAMユーザーを作成して、ACCESS_KEYとSECRET_KEYを取得
- IAMユーザーに以下のポリシーを設定
```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"cloudformation:*",
				"lambda:*",
				"iam:CreateRole",
				"iam:AttachRolePolicy",
				"iam:DetachRolePolicy",
				"iam:PassRole",
				"iam:DeleteRole",
				"iam:GetRole",
				"iam:TagRole",
				"tag:TagResources",
				"tag:UntagResources",
				"logs:*",
				"s3:*"
			],
			"Resource": "*"
		}
	]
}
```
- AWS CLIのプロファイルを設定します。
```bash
aws configure --profile {your-profile-name}

# 下記を入力
AWS Access Key ID [None]: {your-access-key-id}
AWS Secret Access Key [None]: {your-secret-access-key}
Default region name [None]: us-east-1
Default output format [None]: json
```

### 2. デプロイコマンド（初回のみ）

`mv samconfig.toml.sample samconfig.toml` で `samconfig.toml` を作成

```bash
sam deploy --guided --profile {your-profile-name}
# 次のとおりに入力
	Setting default arguments for 'sam deploy'
	=========================================
	Stack Name [ses-feedback-to-slack]:
	AWS Region [us-east-1]:
	#Shows you resources changes to be deployed and require a 'Y' to initiate deploy
	Confirm changes before deploy [Y/n]: Y
	#SAM needs permission to be able to create roles to connect to the resources in your template
	Allow SAM CLI IAM role creation [Y/n]: Y
	#Preserves the state of previously provisioned resources when an operation fails
	Disable rollback [y/N]: N
	Save arguments to configuration file [Y/n]: Y
	SAM configuration file [samconfig.toml]:
	SAM configuration environment [default]:
```

初回は `--guided` を使うことで `samconfig.toml` に設定が保存されます。
次回からは以下のコマンドのみで再デプロイできます：

```bash
sam deploy
```

---

## 🔁 ローカル実行

### 1. テストイベントを用意

`events/` ディレクトリにテスト用の JSON ファイルがあります。

### 2. 実行

バウンス
```bash
sam local invoke --event events/bounce.json --env-vars .env.json
```

苦情
```bash
sam local invoke --event events/complaint.json --env-vars .env.json
```

---

## 🧪 単体テスト

モックを使っているので Slack に通知は届きません。

```bash
ruby test/app_test.rb
```

---

## ✅ Slack 通知例

バウンス通知：

```
🛎️ バウンス通知
📩 user@example.com
(5.1.1, smtp; 550 5.1.1 user unknown)
{JSONをそのまま出力}
```

苦情通知：

```
🚨 苦情（Complaint）通知
📩 spam@example.com
{JSONをそのまま出力}
```

---

## 📎 補足メモ

- IAMの権限が広すぎるので、必要に応じて制限してください。 
- デプロイ失敗時にはロールバックが行われ、不要なリソースを削除してくれるはずなのですが、初回デプロイでエラーになった場合、ロールバックも失敗する可能性が高いです。ロールバックが失敗すると、デプロイできなくなるので、いったんCloudFormationのコンソールからスタックをまるごと削除してください。
