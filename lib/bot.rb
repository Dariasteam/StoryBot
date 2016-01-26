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
      while(texto.include?("@"))
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

def guardaEscena(numero,escena)
  if(!@escenas.key(numero).is_a? Escena)
    @escenas[numero]=escena
    ""
  else
    "[!] La escena #{numero} se define dos veces. "
  end
end

def analizador(flujo)
  opciones = []
  escenasHuerfanas = []
  @escenas = {}
  @autor = nil
  @titulo = nil
  estado = "0"
  errores = ""
  contenido = ""
  index = 0
  indexl = 1
  flujo << "\n\n"
  flujo.each_line do |line|
    #operaciones con una nueva escena---------------------------------------------------------------
        #puts "linea #{indexl}"
    if(contenido.match("#"))
      @autor = contenido[/\#(.*?)#/,1]
      contenido = contenido.sub(/\#(.*?)#/,'')
    end
    if(contenido.match("{"))
      @titulo = contenido[/\{(.*?)}/,1]
      contenido = contenido.sub(/\{(.*?)}/,'')
    end
    if(line.match(/<*>/))
      if(estado == "0" || estado == "B")
        estado = "A"
      elsif(estado == "A")
        auxContenido = contenido.split(/</)[1]
        errores << guardaEscena(auxContenido[/(.*?)>/,1].to_i,Escena.new(auxContenido.partition(/.>/).last,[]))
        escenasHuerfanas.delete(auxContenido[/(.*?)>/,1].to_i)
        contenido = ""
      elsif(estado == "D")
        errores << guardaEscena(index,Escena.new(@escenas[index].partition(/<*>/).last,opciones))
        escenasHuerfanas.delete(index)
        opciones = []
        estado = "A"
        contenido = ""
      else
        if(@escenas[contenido[/\<(.*?)>/,1].to_i] == nil)
          errores << "[!] no se esperaba '<*>' en la línea #{indexl}\n#{line}"
        end
      end
    end
    if(contenido.match(/-/))
      if(estado == "A")
        index = contenido[/\<(.*?)>/,1].to_i
        @escenas[index] = contenido.partition("-").first
        contenido = contenido.partition('-').last
        estado = "C"
      elsif(estado == "D")
        contenido = contenido.partition('-').last
        estado = "C"
      else
        errores << "[!] no se esperaba '-' en la línea #{indexl}\n#{contenido}"
      end
    end
    if(contenido.match(/@/))
      numero = contenido.partition("@").last.to_i
      if(@escenas.key?(numero) == false && !escenasHuerfanas.include?(numero))
            escenasHuerfanas << numero
      end
      if(contenido.count("@") == 1 && estado != "D")
        if(estado == "A")      #fin de la escena
          if(contenido[contenido.index("@")+1..-1].to_i == contenido[/\<(.*?)>/,1].to_i)
            errores << "[!] las escenas no pueden referenciarse a sí mismas"
          else
            errores << guardaEscena(contenido[/\<(.*?)>/,1].to_i,Escena.new(contenido.partition(/<*>/).last,[]))
            escenasHuerfanas.delete(contenido[/\<(.*?)>/,1].to_i)
            estado = "B"
            contenido = ""
          end
        elsif(estado == "C")
          opciones << [contenido.partition("@").first,contenido.partition("@").last.to_i]
          estado = "D"
          contenido = ""
        else
          errores << "[!] no se esperaba '@' en la línea #{indexl}\n#{line}"
        end
      else
        errores << "[!] solo se puede declarar una referencia por opción"
      end
    end
    contenido = contenido + line
    indexl = indexl + 1
  end
  if(contenido.split!=[])
    if(opciones!=[])
      @escenas[index] = Escena.new(@escenas[index].partition(/<*>/).last,opciones)
      escenasHuerfanas.delete(index)
    else
      index = contenido[/\<(.*?)>/,1].to_i
      @escenas[index] = Escena.new(contenido.partition(/<*>/).last,opciones)
      escenasHuerfanas.delete(index)
    end
  end
  #alertas y errores-----------------------------------------------------------------------------------
  if(escenasHuerfanas.size>0)
    errores << "[!] Las escenas #{escenasHuerfanas} son referenciadas pero no están declaradas\n"
  end
  if(@titulo == nil)
    errores << "[!] La historia no tiene título\n"
  end
  if(@autor == nil)
    errores << "[!] La historia no tiene autor\n"
  end
  if(@escenas.length < 1)
    errores << "[!] La historia debe tener al menos una escena\n"
  end
  puts "Generadas #{@escenas.length} escenas\n\n"
  if(errores!="")
    errores
  else

  end
end

class Historia                              #Una instancia por cada fichero en /Historias, contiene Escenas
  attr_reader :escenas, :titulo, :autor
  def initialize(uri)
    analizador(uri)
  end
end

def inicio
  "Envía 'start' para volver a\n"+
   "este menú en cualquier \nmomento\n\n"+
   "1 Jugar historias\n2 Enviar historia\n3 Editar historia"
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
  <3> Esta es la escena 3, lleva siempre a 0. Las llamadas pueden encadenarse cuantas veces se quiera"
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
hHistorias = {}

master = File.read("Historias/master")
aux = ""

#Carga del fichero master y según lo especificado busca los *.bot
master.split.map do |linea|
  if(linea.length > 20)
    aux = linea
  else
    hHistorias[aux] = linea.to_i
    puts "Cargado 'Historias/#{linea}.bot'"
    vHistorias[linea.to_i] = Historia.new(File.read("Historias/#{linea}.bot"))
  end
end

def guardarClaves(hHistorias)
  string = ""
  hHistorias.map do |hash|
    string << "#{hash[0]}\n#{hash[1]}\n"
  end
  File.open("Historias/master", "w") { |f| f.write(string) }
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

        guardarClaves(hHistorias)



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

        guardarClaves(hHistorias)

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
