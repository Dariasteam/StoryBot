# coding: utf-8
require "bot/version"
require "bot/escena"
require "bot/historia"
require "bot/juego"

require 'telegram/bot'


class ServerBot

  def initialize
    @connections = {} # Hash User/Group Fiber
    @vHistorias = [] # Historias
    cargarHistorias

    puts " ~ Iniciando el bot"
    token = File.open("telegram.token","r").read.strip
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        puts " ~ reply"
        if not @connections.key? message.from.username
          p " ~ @#{message.from.username} se ha unido"
          @connections[message.from.username] = Fiber.new do |bot, message|
            inicio bot, message
          end
        end
        @connections[message.from.username].resume bot, message
        puts message.text
      end
    end
  end

  def cargarHistorias
    index = 0
    while(File.exist?("Historias/#{index}.bot"))
      puts "Cargado 'Historias/#{index}.bot'"
      @vHistorias[index] = Historia.new(File.read("Historias/#{index}.bot"))
      index += 1
    end
  end

  def inicioHistorias(vector)
    text = "Tienes a elegir entre las siguientes historias:\n\n"
    for i in 0..vector.size - 1 do
      text << "#{i+1}\t #{vector[i].titulo}, por #{vector[i].autor} \n"
    end
    text
  end

  def inicio bot, message
    bot.api.send_message(chat_id: message.chat.id, text: Juego.inicio)
    bot, message = Fiber.yield
    case message.text
    when "1"
      bot.api.send_message(chat_id: message.chat.id, text: inicioHistorias(@vHistorias))
      bot, message = Fiber.yield
      jugar bot, message

    when "2"
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Enviame un mensaje con el formato siguiente: ")
      bot.api.send_message(chat_id: message.chat.id, text: Historia.ejemplo)
      bot, message = Fiber.yield
      introducir_historia bot, message

    when "3"
      modificar_historia bot, message

    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text}")
      inicio bot, message
    end
  end

  def jugar bot, message
    puts " ~ @#{message.from.username} ha elegido Jugar"

    if @vHistorias.key? message.text
      puts " ~ @#{message.from.username} ha elegido la historia (#{message.text.to_i-1}) #{vHistorias[message.text.to_i-1].titulo}"
      juego = Juego.new(@vHistorias[message.text.to_i-1])
      begin
        bot.api.send_message(
          chat_id: message.chat.id,
          text: juego.mostrar)
        bot, message = Fiber.yield
        juego.entrada(message.text)
      end while not /\/start/ =~ message.text
      inicio message, message.text
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text.inspect}")
      inicio bot, message
    end
  end

  def introducir_historia bot, message
    puts " ~ @#{message.from.username} ha elegido Crear Historias"
  end

  def modificar_historia bot, message
    puts " ~ @#{message.from.username} ha elegido Modificar Historias"
  end
end

server = ServerBot.new
