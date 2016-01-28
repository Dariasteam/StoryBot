# coding: utf-8
require "bot/escena"

class Historia                              #Una instancia por cada fichero en /Historias, contiene Escenas
  attr_reader :escenas, :titulo, :autor

  private_class_method :new  # que complicado hacer una estupides

  def self.from_string str
    object = new
    object.analizador(str)
    object
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

  def analizador(flujo) # TODO esto necesita una limpieza
    opciones = []
    escenasHuerfanas = []
    @escenas = {}
    @autor = nil
    @titulo = nil
    estado = "0"
    errores = ""
    index = 0
    indexl = 1
    buff = ""
    flujo << "\n\n"
    flujo.each_line do |line|
      line.split.map do |s|
        if(s.match(/#(.*?)#/))
          @autor = s[/#(.*?)#/,1]
        elsif(line.match(/\{(.*?)\}/))
          @titulo = line[/\{(.*?)\}/,1]
        elsif(s.match(/<(.+?)>/))
          if(estado == "0")
            estado = "A"
          elsif(estado == "B" || estado == "D" || estado == "A")
            @escenas[index] = Escena.new(buff,opciones)
            if(escenasHuerfanas.include?(index)); escenasHuerfanas.delete(index); end
            estado = "A"
            index = s[/<(.+?)>/,1].to_i
            opciones = []
            buff = ""
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        elsif(s.match(/~/))
          if(estado == "A" || estado == "D")
            opciones << [s.delete("~")+" ",nil]
            estado = "C"
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        elsif(s.match(/@/))
          dir = s.partition("@").last.to_i
          if(!@escenas.key?(dir) && !escenasHuerfanas.include?(dir)); escenasHuerfanas << dir; end
          if(estado == "A")
            estado = "B"
          elsif(estado == "C")
            opciones[-1][1] = s.partition("@").last.to_i
            estado = "D"
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        else
          if(estado=="C")
            opciones[-1][0] << s+" "
          else
            buff << s+" "
          end
        end
      end
      indexl = indexl + 1
    end
    #ultima escena--------------------------------------------------------------------------------------
    if(estado=="A" || estado=="D")
      @escenas[index] = Escena.new(buff,opciones)
      if(escenasHuerfanas.include?(index)); escenasHuerfanas.delete(index); end
    elsif(estado=="C")
      errores << "[!] se esperaba '@' en la línea #{indexl}\n"
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
    end
  end
end
