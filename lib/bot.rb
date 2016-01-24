require "bot/version"
require 'telegram_bot'

class Escena
  attr_reader :contenido
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

class Juego                                  #Uno por jugador, emplea la información de la clase Historia
  def initialize(historia)
    @escenas = historia.escenas
    @actual = @escenas[0]
  end
  def entrada(command)
    if(@actual!=nil)
      actual = @actual.entrada(command)
      if(actual!=nil)
        @actual = @escenas[actual]
      else
        nil
      end
    end
  end
  def mostrar
    if(@actual!= nil)
      texto = @actual.mostrar
      if(texto.include?("@"))
        numero = texto[texto.index('@')+1..-1].to_i
        texto = texto[0..texto.index('@')-1]
        @actual = @escenas[numero]
        texto << "\n#{@actual.mostrar}"
      end
      texto
    end
  end
  def reiniciar
    @actual = @escenas[0]
    @actual.mostrar
  end
  def getEscena
    @escenas.key(@actual)
  end
end

class Historia                              #Una instancia por cada fichero en /Historias, contiene Escenas
  attr_reader :escenas, :titulo, :autor
  def initialize(uri)
    @escenas = {}
    puts "Cargando #{uri}"
    File.open(uri,"r") do |flujo|         #apertura en modo r del fichero
      opciones = []
      ini = false
      contenido = ""
      escenasHuerfanas = []
      while line = flujo.gets do
        #operaciones con una nueva escena---------------------------------------------------------------
        if(line.match(/<*>/))
          if(ini==false)
            ini = true
          else
            texto = contenido.sub(/<.>/,'').delete("\n").delete("\t")
            escena = Escena.new(texto,opciones)
            numero = contenido[contenido.index('<')+1..contenido.index('>')-1].to_i
            if(@escenas[numero]==nil)
              @escenas[numero] = escena
              escenasHuerfanas.delete(numero)
            else
              puts "Error, la escena #{numero} ya ha sido definida como:"+
              "\n\n'#{@escenas[numero].contenido}'"
            end
            opciones = []
            salto = nil
          end
          contenido = line
        #operaciones con las opciones de una escena--------------------------------------------------------
        elsif(line.match(/-/))
          line.slice! ("-")
          opciones << [line[0..line.index('@')-1],(line[line.index('@')+1..-1]).to_i]
          numero = (line[line.index('@')+1..-1]).to_i
          if(@escenas[numero] == nil && !escenasHuerfanas.include?(numero))
            escenasHuerfanas << numero
          end
        elsif(line.match(/{*}/))
          #puts "El Título es #{line.delete('{').delete('}')}"
          @titulo = line.delete('{').delete('}').delete("\n")
        elsif(line.match(/#*#/))
          #puts "El Autor es #{line.delete('#')}"
          @autor = line.delete('#').delete("\n")
        else
          contenido = contenido + line
        end
      end
      if(contenido.match(/<*>/))
        numero = (contenido[contenido.index('<')+1..contenido.index('>')-1].to_i)
        escenasHuerfanas.delete(numero)
        @escenas[numero] = Escena.new(contenido.sub(/<.>/,''),opciones)
      end
      #alertas y errores-----------------------------------------------------------------------------------
      if(escenasHuerfanas.size>0)
        puts "[!] Las escenas #{escenasHuerfanas} son referenciadas pero no están declaradas"
      end
      if(@titulo == nil)
        puts "[!] La historia no tiene título"
      end
      if(@autor == nil)
        puts "[!] La historia no tiene autor"
      end
      puts "Generadas #{@escenas.length} escenas\n\n"
    end
  end
end

def inicio
  "1 Jugar historias\n2 Enviar historia\n"
end

def ejemplo
  "#Autor#
  {Nombre_Historia}

  <0> Esto es la descripción de la escena 0
      Esto sigue siéndolo, no cambiará hasta
      que aparezca un guión

        -Esta es la primera opción, lleva a 1 @1
        -Esta es la segunda opción, lleva a 2 @2

  <1> Esto es la escena 1

        -Opcion A, lleva a 0 @0
        -Opcion B, lleva a 2 @2
        -Opcion C, lleva a 3 @3

  <2> Esta es la escena 2, no tiene opciones, pero lleva a 3 siempre @3
  <3> Esta es la escena 3, no tiene opciones y se repetirá siempre"
end

def inicioHistorias(vector)
  text = "Tienes a elegir entre las siguientes historias:\n\n"
  for i in 0..vector.size - 1 do
    text << "#{i+1}\t #{vector[i].titulo}, por #{vector[i].autor} \n"
  end
  text
end

puts "Iniciando servidor"
#incialización del bot
token = File.open("telegram.token","r").read.gsub(/\n/,"").delete('\n')
bot = TelegramBot.new(token: token)
#inicialización de las historias
Partidas = {}
vHistorias = []
index = 0
while(File.exist?("Historias/#{index}.bot"))
  vHistorias[index] = Historia.new("Historias/#{index}.bot")
  index = index +1
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
        reply.text = inicio(vHistorias)
      end
    elsif(Partidas[message.from.username] == "creando")
      File.open("Historias/#{vHistorias.size}.bot", "w") do |f|
        f.write(command)
      end
      puts " ~ @#{message.from.username} ha creado una nueva historia"
      reply.text = "Tu historia ha sido creada correctamente"
      vHistorias << Historia.new("Historias/#{vHistorias.size}.bot")
    elsif(Partidas[message.from.username]!= nil)
      puts " --> @#{message.from.username}: #{Partidas[message.from.username].getEscena}"
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
