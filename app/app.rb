require 'json'
require 'net/http'
require 'uri'

def lambda_handler(event:, context:)
  message_json = event['Records'][0]['Sns']['Message']
  message = JSON.parse(message_json)
  notification_type = message['notificationType']

  case notification_type
  when 'Bounce'
    slack_message = bounce_text(message, message_json)
    post_to_slack(slack_message)
  when 'Complaint'
    slack_message = complaint_text(message, message_json)
    post_to_slack(slack_message)
  else
    puts "Unsupported notificationType: #{notification_type}"
  end

  { statusCode: 200, body: JSON.generate('OK') }
end

def bounce_text(message, raw_message)
  bounced_recipients = message['bounce']['bouncedRecipients']
  bounce_info = bounced_recipients.map do |recipient|
    "📩 #{recipient['emailAddress']} \n(#{recipient['status']}, #{recipient['diagnosticCode']})"
  end.join("\n")

  slack_message = {
    text: "🛎️ *バウンス通知*\n#{bounce_info}\n```#{raw_message.truncate(2800)}```"
  }
end

def complaint_text(message, raw_message)
  complained_recipients = message['complaint']['complainedRecipients']
  complaint_info = complained_recipients.map do |recipient|
    "📩 #{recipient['emailAddress']}"
  end.join("\n")

  slack_message = {
    text: "🚨 *苦情（Complaint）通知*\n#{complaint_info}\n```#{raw_message.truncate(2800)}```"
  }
end

def post_to_slack(payload)
  webhook_url = ENV['SLACK_WEBHOOK_URL']
  uri = URI.parse(webhook_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
  request.body = payload.to_json

  response = http.request(request)

  unless response.is_a?(Net::HTTPSuccess)
    raise "Slack post failed: #{response.code} #{response.body}"
  end
end

class String
  def truncate(max)
    self.length > max ? self[0, max] + "..." : self
  end
end
