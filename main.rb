# frozen_string_literal: true

require 'telegram/bot'
require 'base64'
require 'dotenv'

Dotenv.load('.env')

token = ENV['BOT_TOKEN']
available_chat_ids = ENV['AVAILABLE_CHAT_IDS'].split(',')

def encode64(text)
  Base64.encode64(text)
end

def decode64(text)
  Base64.decode64(text)
end

class Logger
  def self.log(message)
    time = Time.new.strftime('%d/%m/%y %H:%M:%S')
    timed_message = "#{time} -> #{message}\n"

    puts timed_message
    File.write("logs.txt", timed_message, mode: "a")
  end
end

puts 'Bot running'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    logged = available_chat_ids.map(&:to_i).include?(message.chat.id)
    if logged
      command, arg = message.text.split(' ', 2)

      case command
      when '/encode64'
        encoded64 = encode64(arg)

        Logger.log("Encoding: #{arg}")

        bot.api.send_message(chat_id: message.chat.id, text: encoded64)
        bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
      when '/decode64'
        decoded = decode64(arg)

        Logger.log("Decoding: #{arg}")

        Thread.new do
          sent_message = bot.api.send_message(chat_id: message.chat.id, text: decoded.to_s)
          sent_message_id = sent_message['result']['message_id']
          sent_chat_id = sent_message['result']['from']['id']

          bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
          sleep(5)
          bot.api.delete_message(chat_id: message.chat.id, message_id: sent_message_id)
        end
      when '/logs'
        Logger.log('Logging the file')

        Thread.new do
          file = File.open('logs.txt').read
          sent_message = bot.api.send_message(chat_id: message.chat.id, text: file.to_s)
          sent_message_id = sent_message['result']['message_id']
          sent_chat_id = sent_message['result']['from']['id']

          bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
          sleep(10)
          bot.api.delete_message(chat_id: message.chat.id, message_id: sent_message_id)
        end
      end
    end

  rescue StandardError => e
    Logger.log(e)
  end
end
