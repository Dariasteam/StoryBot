require "bot/version"
require 'telegram_bot'

class Nodo
  def initialize(contenido, opciones = [])
    @contenido = contenido
    @opciones = opciones
    @salidas = {}
    for i in 0..@opciones.size - 1 do
      @salidas[i] = @opciones[i][1]
    end
  end
  def mostrar
    mensaje = @contenido + "\n\n"
      for i in 0..@opciones.size - 1 do
        mensaje = mensaje + "#{i+1} #{@opciones[i][0].to_s}\n"
      end
      mensaje
  end
  def entrada(command)
    if((command.to_i) - 1 == -1)
      nil
    else
      @salidas[(command.to_i) - 1]
    end
  end
end

class Juego
  def initialize
    @nodos = []
    File.open("../prueba.bot","r") do |flujo|
      opciones = []
      ini = false
      contenido = ""
      while line = flujo.gets do
        if(line.match(/<*>/))
          if(ini==false)
            ini = true
          else
            @nodos << Nodo.new(contenido.sub(/<.>/,'').delete("\n").delete("\t"),opciones)
            opciones = []
          end
          contenido = line
        elsif(line.match(/-/))
          line.slice! ("-")
          opciones << [line[0..line.index('@')-1],(line[line.index('@')+1..-1]).to_i]
        else
          contenido = contenido + line
        end
      end
      @nodos << Nodo.new(contenido.sub(/<.>/,''),opciones)
      puts "generados #{@nodos.size}"
    end
    @actual = @nodos[0]
  end
  def entrada(command)
    actual = @actual.entrada(command)
    if(actual!=nil)
      @actual = @nodos[actual]
    else
      nil
    end
  end
  def mostrar
    @actual.mostrar
  end
  def reiniciar
    @actual = @nodos[0]
    @actual.mostrar
  end
end

bot = TelegramBot.new(token: '143179136:AAHQKOCWGAbPvlL5loKqI2lyyVopktargM0')
K = Juego.new
bot.get_updates(fail_silently: true) do |message|
  puts "@#{message.from.username}: #{message.text}"
  command = message.get_command_for(bot)
  message.reply do |reply|
    K.entrada(command)
    case command
    when /start/i
      reply.text = K.reiniciar
    else
      if((reply.text = K.mostrar)==nil)
        puts "aqui nil"
        reply.text = "#{message.from.first_name}, no tengo ni idea de lo que significa #{command.inspect}"
      end
    end
    puts "Enviando #{reply.text.inspect} a @#{message.from.username}"
    reply.send_with(bot)
  end
end
