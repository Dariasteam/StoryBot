# coding: utf-8
require "bot/version"
require "bot/escena"
require "bot/historia"
require "bot/juego"

require 'telegram_bot'


class ServerBot

  def initialize
    puts " ~ Iniciando servidor"
    #incialización del bot
    token = File.open("telegram.token","r").read.gsub(/\n/,"").delete('\n')
    @bot = TelegramBot.new(token: token)

    @connections = {} # Hash User/Group Fiber


    vHistorias = [] # todo nose
    hHistorias = {} # todo nose
    index = 0
    while(File.exist?("Historias/#{index}.bot"))
      puts "Cargado 'Historias/#{index}.bot'"
      vHistorias[index] = Historia.new(File.read("Historias/#{index}.bot"))
      index = index + 1
    end
    bool = true
    aux = ""

    File.open("Historias/master", "r").each do |line|
      if(bool)
        aux = line.delete("\n")
      else
        hHistorias[aux] = line.to_i
      end
      bool = !bool
    end

    @bot.get_updates(fail_silently: true) do |message|
      command = message.get_command_for(@bot)
      message.reply do |reply|
        if not @connections.key? message.from.username
          @connections[message.from.username] = Fiber.new do |message, command, reply|
            inicio message, command, reply
          end
        end
        @connections[message.from.username].resume message, command, reply
      end
    end
  end

  def inicioHistorias(vector)
    text = "Tienes a elegir entre las siguientes historias:\n\n"
    for i in 0..vector.size - 1 do
      text << "#{i+1}\t #{vector[i].titulo}, por #{vector[i].autor} \n"
    end
    text
  end

  def inicio message, command, reply
    p " ~ @#{message.from.username} se ha unido"
    reply.text = Jugar.inicio
    reply.send_with(@bot)
    Fiber.yield
    case message
    when "1"
      reply.text = inicioHistorias(vHistorias)
      reply.send_with(@bot)
      Fiber.yield
      jugar message, command, reply
    when "2"
      reply.text = "Enviame un mensaje con el formato siguiente: "
      reply.send_with(@bot)
      reply.text = Historia.ejemplo
      reply.send_with(@bot)
      Fiber.yield
      introducir_historia message, command, reply
    when "3"
      modificar_historia message, command, reply
    else
      reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
      reply.send_with(@bot)
      inicio message, command, reply
    end
  end

  def jugar message, command, reply
    puts " ~ @#{message.from.username} ha elegido Jugar"

    if vHistorias.key? command
      puts " ~ @#{message.from.username} ha elegido la historia (#{command.to_i-1}) #{vHistorias[command.to_i-1].titulo}"
      juego = Juego.new(vHistorias[command.to_i-1])
      begin
        reply.text = juego.mostrar
        reply.send_with(@bot)
        Fiber.yield
        juego.entrada(command)
      end while not /\/start/ =~ command
      inicio message, command, reply
    else
      reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
      reply.send_with(bot)
      inicio message, command, reply # TODO no tan lejos
    end
  end

  def introducir_historia message, command, reply # TODO
    puts " ~ @#{message.from.username} ha elegido Crear Historias"
    reply.text = "Envíame un mensaje con el formato siguiente: "
    reply.send_with(bot)
    reply.text = ejemplo
  end

  def modificar_historia message, commnad, reply # TODO
    puts " ~ @#{message.from.username} ha elegido Modificar Historias"

  end
end




#incio del bot
bot.get_updates(fail_silently: true) do |message|
  command = message.get_command_for(bot)
  message.reply do |reply|
    if(Partidas[message.from.username] == nil || command =~ /start/i)
      puts " ~ @#{message.from.username} se ha unido"
      reply.text = inicio
      Partidas[message.from.username] = "esperandomodo"
    elsif(Partidas[message.from.username] == "esperandomodo")
      if(command.to_i == 1)
        puts " ~ @#{message.from.username} ha elegido Jugar"
        Partidas[message.from.username] = "esperandojuego"
        reply.text = inicioHistorias(vHistorias)
      elsif(command.to_i == 2)


        puts " ~ @#{message.from.username} ha elegido Crear"
        Partidas[message.from.username] = "creando"
        reply.text = "Envíame un mensaje con el formato siguiente: "
        reply.send_with(bot)
        reply.text = ejemplo
      elsif(command.to_i == 3)
        puts " ~ @#{message.from.username} ha elegido Editar"
        reply.text = "Envíame la clave de tu historia"
        Partidas[message.from.username] = "editando"
      else
        reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
        reply.send_with(bot)
        reply.text = inicio
      end

    elsif(Partidas[message.from.username] == "esperandojuego")
      if(command.to_i <= vHistorias.size && command.to_i > 0)
        puts " ~ @#{message.from.username} ha elegido la historia (#{command.to_i-1}) #{vHistorias[command.to_i-1].titulo}"
        Partidas[message.from.username] = Juego.new(vHistorias[command.to_i-1])
        reply.text = Partidas[message.from.username].mostrar
      else
        reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
        reply.send_with(bot)
        reply.text = inicio
      end
    elsif(Partidas[message.from.username] == "creando")
      aux = analizador(command)
      if(aux.is_a? String)
        reply.text = aux + "\n\n Prueba de nuevo"
      else
        puts " ~ @#{message.from.username} ha creado una nueva historia"
        File.open("Historias/#{vHistorias.size}.bot", "w") do |f|
          f.write(command+"\n")
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

        vHistorias << Historia.new(command)

        string = ""
        for i in 0..vHistorias.count-1 do
          puts "i : #{i}"
          string << hHistorias.key(i) + "\n#{i}\n"
        end
        File.open("Historias/master", "w") do |f|
          f.write(string)
        end

        Partidas[message.from.username] = "esperandomodo"
      end
    elsif(Partidas[message.from.username]== "editando")
      if(hHistorias[command]==nil)
        reply.text = "[!] La clave no es correcta"
      else
        reply.text = "Recuperando historia\n"
        reply.send_with(bot)
        reply.text = File.read("Historias/#{hHistorias[command]}.bot")
        Partidas[message.from.username] = hHistorias[command].to_i
      end
    elsif(Partidas[message.from.username].is_a? Integer)
      aux = analizador(command)
      if(aux.is_a? String)
        reply.text = aux + "\n\n Prueba de nuevo"
      else
        puts " ~ @#{message.from.username} ha editado la historia #{Partidas[message.from.username]}"+
             " #{vHistorias[Partidas[message.from.username]]}"
        File.open("Historias/#{Partidas[message.from.username]}.bot", "w") do |f|
          f.write(command+"\n")
        end
        reply.text = "Has editado tu historia correctamente"
        reply.send_with(bot)
        vHistorias[Partidas[message.from.username]] = Historia.new(command)

        string = ""
        for i in 0..vHistorias.count-1 do
          string << hHistorias.key(i) + "\n#{i}\n"
        end
        File.open("Historias/master", "w") do |f|
          f.write(string)
        end

        Partidas[message.from.username] = "esperandomodo"
        reply.text = inicio
      end
    elsif(Partidas[message.from.username]!= nil)
      puts " --> @#{message.from.username}: #{command}"
      command = message.get_command_for(bot)
      Partidas[message.from.username].entrada(command)
      if((reply.text = Partidas[message.from.username].mostrar)==nil)
        reply.send_with(bot)
        reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
      end
      puts " <-- @#{message.from.username} <#{Partidas[message.from.username].getEscena}>"
    end
    reply.send_with(bot)
  end
end

#recorrer historias para averiguar posibles bucles
#~eliminar error saltos de linea
#usar split en el parseador
