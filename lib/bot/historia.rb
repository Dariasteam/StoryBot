# coding: utf-8


class Historia                              #Una instancia por cada fichero en /Historias, contiene Escenas
  attr_reader :escenas, :titulo, :autor
  def initialize(uri)
    analizador(uri)
  end

  def self.ejemplo
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
    if(contenido!="\n\n")
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
end
