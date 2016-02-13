# coding: utf-8
require "bot/version"
require "bot/escena"
require "bot/historia"
require "bot/juego"
require 'telegram/bot'


class ServerBot
  def initialize
    @connections = {} # Hash User/Group Fiber
    @Historias  = []
    @hKeyId  = {}  #Pares key/id de las historias
    cargarHistorias
    puts " ~ Iniciando el bot"
    token = File.open("telegram.token","r").read.strip
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        puts " ~ reply #{message.chat.id}"
        if not @connections.key? message.chat.id
          puts " ~ @#{message.from.username} se ha unido"
          @connections[message.chat.id] = Fiber.new do |boti, messagi|
            inicio boti, messagi
          end
        end
        puts "--> @#{message.from.username} #{message.text}"
        if(message.text!=nil && !message.text.empty?)
          @connections[message.chat.id].resume bot, message
        end
      end
    end
  end

  def cargarHistorias
    #Carga del fichero máster y según lo especificado busca los *.bot
    aux = ""
    File.read("Historias/master").split.map do |linea|
      if(linea.length > 20)
        aux = linea
      else
        @hKeyId[aux] = linea.to_i
        puts "Cargado 'Historias/#{linea}.bot'"
        @Historias << Historia.new(File.read("Historias/#{linea}.bot"))
      end
    end
  end

  def guardarClaves
    #actualiza los pares key/id del fichero master
    string = ""
    @hKeyId.map do |hash|
      string << "#{hash[0]}\n#{hash[1]}\n"
    end
    File.open("Historias/master", "w") { |f| f.write(string) }
  end

  def inicioHistorias
    text = "Tienes a elegir entre las siguientes historias:\n\n"
    i = 1
    @Historias.map do |v|
      text << "#{i}\t #{v.titulo}, por #{v.autor} \n"
      i = i + 1
    end
    [text,i]
  end

  def inicio bot, message
    keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:
    [[1,2,3]], resize_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: Juego.inicio, reply_markup: keyboard)
    bot, message = Fiber.yield
    message.text = message.text.delete("/")
    case message.text
    when "1"
      keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:
      (1..inicioHistorias[1]-1).to_a.each_slice(4).to_a, resize_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: inicioHistorias[0],reply_markup: keyboard)
      bot, message = Fiber.yield
      jugar bot, message
    when "2"
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Enviame un mensaje con el formato siguiente: ")
      kb = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: Historia.ejemplo, reply_markup: kb)
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
    message.text = message.text.delete("/")
    if(@Historias.length >= message.text.to_i && message.text.to_i > 0)
      puts " ~ @#{message.from.username} ha elegido la historia (#{message.text.to_i}) #{@Historias[message.text.to_i-1].titulo}"
      juego = Juego.new(@Historias[message.text.to_i-1])
      t = ""
      while(!(message.text =~ /start/))     #evita envío de mensaje vacio
          t = juego.mostrar[0]
          keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:
          (1..juego.mostrar[1]).to_a.each_slice(4).to_a, resize_keyboard: true)
          if(t== nil || t.empty? || t=="")
            t = "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text}"
          end
            bot.api.send_message(chat_id: message.chat.id, text: t,reply_markup: keyboard)
          bot, message = Fiber.yield
          message.text = message.text.delete("/")
          juego.entrada(message.text)
      end
      inicio bot, message
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text.inspect}")
      inicio bot, message
    end
  end

  def operaciones_historia bot, message, historia, key
    if(message.text =~ /start/); return 0; end
    aux = historia.analizador(message.text)
    if(aux.kind_of? String)
      bot.api.send_message(chat_id: message.chat.id, text: aux + "\n\nPrueba de nuevo")
      return false
    else
      File.open("Historias/#{@Historias.size}.bot", "w") do |f|
        f.write(message.text+"\n")
      end
      if(key==nil)                                              #comprobar si editamos o creamos
        key = (0...50).map { ('a'..'z').to_a[rand(26)] }.join   #crear clave
        @hKeyId[key] = @Historias.count                         #añadir historia al Hash de claves                                  #añadir historia al Array
        guardarClaves
      end
      @Historias[@hKeyId[key]] = historia
      return key
    end
  end

  def introducir_historia bot, message
    puts " ~ @#{message.from.username} ha elegido Crear Historias"
    key = false
    key = operaciones_historia bot, message, Historia.new(message.text), nil
    while(key==false)
      bot, message = Fiber.yield
      message.text = message.text.delete("/")
      key = operaciones_historia bot, message, Historia.new(message.text), nil
    end
    if(key.kind_of? String)
      puts " ~ @#{message.from.username} ha creado una nueva historia"
      text = "¡Felicidades! Tu historia ha sido creada correctamente."+
             "\nGuarda esta clave para poder editarla más adelante: "
      bot.api.send_message(chat_id: message.chat.id, text: text)
      bot.api.send_message(chat_id: message.chat.id, text: key)
    end
    inicio bot, message
  end

  def modificar_historia bot, message
    kb = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
    puts " ~ @#{message.from.username} ha elegido Modificar Historias"
    bot.api.send_message(chat_id: message.chat.id, text: "Introduce la clave de la historia", reply_markup: kb)
    key = false
    bot, message = Fiber.yield
    key = message.text.delete("/")
    while(@hKeyId[key]==nil && !(message.text =~ /start/))
      bot.api.send_message(chat_id: message.chat.id, text: "La clave no es correcta, prueba de nuevo")
      bot, message = Fiber.yield
      key = message.text.delete("/")
    end
    if(!(message.text =~ /start/))
      fin = false
      bot.api.send_message(chat_id: message.chat.id,text: "Recuperando historia")
      bot.api.send_message(chat_id: message.chat.id, text: File.read("Historias/#{@hKeyId[message.text]}.bot"))
      while(fin==false)
        bot, message = Fiber.yield
        message.text = message.text.delete("/")
        fin = operaciones_historia bot, message, Historia.new(message.text), key
      end
      if(fin.kind_of? String)
        puts " ~ @#{message.from.username} ha editado una historia"
        bot.api.send_message(chat_id: message.chat.id,text: "Has editado la historia correctamente")
      end
    end
    inicio bot, message
  end

end

a = ServerBot.new
