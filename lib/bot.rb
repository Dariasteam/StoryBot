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
          @connections[message.chat.id] = Fiber.new do |bot, message|
            inicio bot, message
          end
        end
        puts "--> @#{message.from.username} #{message.text}"
        if(!message.text.empty?)
          @connections[message.chat.id].resume bot, message
        end
      end
    end
  end

  def cargarHistorias
    #Carga del fichero master y según lo especificado busca los *.bot
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
    text
  end

  def inicio bot, message
    bot.api.send_message(chat_id: message.chat.id, text: Juego.inicio)
    bot, message = Fiber.yield
    message.text = message.text.delete("/")
    case message.text
    when "1"
      bot.api.send_message(chat_id: message.chat.id, text: inicioHistorias)
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
    message.text = message.text.delete("/")
    if(@Historias.length >= message.text.to_i && message.text.to_i > 0)
      puts " ~ @#{message.from.username} ha elegido la historia (#{message.text.to_i}) #{@Historias[message.text.to_i-1].titulo}"
      juego = Juego.new(@Historias[message.text.to_i-1])
      while(!(message.text =~ /start/))     #evita envío de mensaje vacio
          juego.entrada(message.text)
          t = juego.mostrar
          if(t.empty? || t=="")
            t = "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text}"
          end
            bot.api.send_message(
              chat_id: message.chat.id,
              text: t)
          bot, message = Fiber.yield
          message.text = message.text.delete("/")
      end
      inicio bot, message
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "#{message.from.first_name}, no tengo ni idea de lo que significa #{message.text.inspect}")
      inicio bot, message
    end
  end

  def introducir_historia bot, message
    puts " ~ @#{message.from.username} ha elegido Crear Historias"
    aux = analizador(message)
    if(aux.is_a? String)
      reply.text = aux + "\n\n Prueba de nuevo"
    else
      puts " ~ @#{message.from.username} ha creado una nueva historia"
      File.open("Historias/#{vHistorias.size}.bot", "w") do |f|
        f.write(message+"\n")
      end
      pass = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
      File.open("Historias/master", "a") do |f|
        f.write(pass)
        f.write("\n#{vHistorias.size}\n")
      end
      reply.text = "¡Felicidades! Tu historia ha sido creada correctamente."+
                    "\nGuarda esta clave para poder editarla más adelante: "
      reply.send_with(bot)
      reply.text = pass
      reply.send_with(bot)
      reply.text = inicio
      hHistorias[pass] = vHistorias.count
      vHistorias << Historia.new(message)
      guardarClaves(hHistorias)
      Partidas[message.from.username] = "esperandomodo"
    end
  end

  def modificar_historia bot, message
    puts " ~ @#{message.from.username} ha elegido Modificar Historias"
  end
end
