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
    File.write('logs.txt', timed_message, mode: 'a')
  end
end

puts 'Bot running'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    logged = available_chat_ids.map(&:to_i).include?(message.chat.id)
    if logged
      command, arg = message.text.split(' ', 2)
      arg = arg.gsub("\n", '')

      case command
      when '/encode64'
        encoded64 = encode64(arg)

        Logger.log("Encoding: #{arg}")

        bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
        bot.api.send_message(chat_id: message.chat.id, text: encoded64)
      when '/decode64'
        decoded = decode64(arg)

        Logger.log("Decoding: #{arg}")

        Thread.new do
          bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
          sent_message = bot.api.send_message(chat_id: message.chat.id, text: decoded.to_s)
          sent_message_id = sent_message['result']['message_id']
          sleep(1.5)
          bot.api.delete_message(chat_id: message.chat.id, message_id: sent_message_id)
        end
      when '/bulk_decode64'
        hashes = arg.split(' ')
        decoded_messages = hashes.map { |hash| "• #{decode64(hash)}" }.join("\n\n")

        Logger.log("Bulk decoding: #{hashes}")

        Thread.new do
          bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)

          sent_message = bot.api.send_message(chat_id: message.chat.id, text: decoded_messages.to_s)

          sent_message_id = sent_message['result']['message_id']

          sleep(15)
          bot.api.delete_message(chat_id: message.chat.id, message_id: sent_message_id)
        end
      when '/ping'
        Logger.log('Ping')

        Thread.new do
          bot.api.send_message(chat_id: message.chat.id, text: 'Pong')
        end
      when '/logs'
        Logger.log('Logging the file')

        Thread.new do
          file = File.open('logs.txt').read
          sent_message = bot.api.send_message(chat_id: message.chat.id, text: file.to_s)
          sent_message_id = sent_message['result']['message_id']

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
