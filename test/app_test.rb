require 'test/unit'
require 'mocha/test_unit'
require_relative '../app/app'

class AppTest < Test::Unit::TestCase
  def test_post_to_slack_makes_http_post
    # テスト用のペイロード, モックのURL設定
    dummy_payload = { text: "Test Message" }
    ENV['SLACK_WEBHOOK_URL'] = 'https://hooks.slack.com/services/test/test/test'

    # モック設定
    uri = URI.parse(ENV['SLACK_WEBHOOK_URL'])
    mock_http = mock('Net::HTTP')
    mock_request = mock('Net::HTTP::Post')
    mock_response = mock('Net::HTTPResponse')

    Net::HTTP.expects(:new).with(uri.host, uri.port).returns(mock_http)
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(uri.request_uri, has_entry('Content-Type' => 'application/json')).returns(mock_request)
    mock_request.expects(:body=).with(dummy_payload.to_json)
    mock_http.expects(:request).with(mock_request).returns(mock_response)
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)

    # 実行
    post_to_slack(dummy_payload)
  end
end
