# coding: utf-8
require "bot/escena"

class Historia                              #Una instancia por cada fichero en /Historias, contiene Escenas
  attr_reader :escenas, :titulo, :autor

  #private_class_method :new  # que complicado hacer una estupides

  def initialize(string)
    analizador(string)
  end

  def self.from_string str
    object = new
    object.analizador(str)
    object
  end

  def self.ejemplo
    #carga desde fichero con el tutorial
    File.read("Historias/example")
  end

#Innecesario con el nuevo parseador

#  def guardaEscena(numero,escena)
#    if(!@escenas.key(numero).is_a? Escena)
#      @escenas[numero]=escena
#      ""
#    else
#      "[!] La escena #{numero} se define dos veces. "
#    end
#  end

#Función recursiva para buscar bucles en los saltos deterministas
  def buscaBucles(i,visitadas)
    if(visitadas[i] == false)
      visitadas[i] = true
      j = @escenas[i].contenido.partition("@").last.to_i
      return buscaBucles(j,visitadas)
    elsif(visitadas[i] == true)
      return "#{i} "
    end
    ""
  end

#Nuevo parser
#Soporte para comentarios y saltos probabilísticos
  def analizador(flujo)
    opciones = []
    probabilistico = []
    escenasHuerfanas = []
    saltosDeterministas = []
    @escenas = {}
    #@autor = nil
    #@titulo = nil
    estado = "A"
    errores = ""
    index = 0
    intervaloMin = 0
    intervaloMax = 0
    indexl = 1
    flujo.each_line do |line|
      line.split.map do |s|
        if(s.match(/\/\//))            #comentarios //
          estado << "-1"
        elsif(estado.match(/-1/))
        elsif(line.match(/#(.*?)#/))
          @autor = line[/#(.*?)#/,1]
        elsif(line.match(/\{(.*?)\}/))
          @titulo = line[/\{(.*?)\}/,1]
        elsif(s.match(/<\d+>/))
          if(estado == "B" || estado == "D" || estado == "A" || estado == "F" || estado == "H")
            index = s[/\d+/].to_i
            @escenas[index] = Escena.new
            @escenas[index].contenido << s.partition(">").last << " "
            if(escenasHuerfanas.include?(index)); escenasHuerfanas.delete(index); end
            estado = "A"
            opciones = []
            probabilistico = []
            intervaloMin = 0
            intervaloMax = 0
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        elsif(s.match(/~/))
          if(estado == "A" || estado == "D" || estado == "H")
            opciones << [s.delete("~")+" ",nil]
            estado = "C"
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        elsif(s.match(/\%\d+/))
          intervaloMax = s[/\d+/].to_i
          if(estado == "A")
            @escenas[index].probabilistico << intervaloMax
            estado = "E"
          elsif(estado == "C")
            probabilistico << intervaloMax
            estado = "G"
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        elsif(s.match(/\(\d+\,@\d+\)/))
          op = s[/\d+,/][/\d+/].to_i
          if(op > intervaloMin && op <= intervaloMax)
            if(estado == "E" || estado == "F")
              @escenas[index].probabilistico << [intervaloMin+1,op,s[/@\d+/][/\d+/].to_i]
              estado = "F"
            elsif(estado == "G" || estado == "H")
              estado = "H"
              probabilistico << [intervaloMin+1,op,s[/@\d+/][/\d+/].to_i]
              if(op == intervaloMax)
                @escenas[index].addOption(opciones[-1][0],probabilistico)
              end
            else
              errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
            end
            intervaloMin = op
          else
            errores << "[!] los parámetros de '#{s}' están fuera de rango .Línea #{indexl}\n#{line}"
          end
        elsif(s.match(/@\d+/))
          dir = s.partition("@").last.to_i
          if(!@escenas.key?(dir) && !escenasHuerfanas.include?(dir)); escenasHuerfanas << dir; end
          if(estado == "A")
            @escenas[index].contenido << s+" "
            saltosDeterministas << index
            estado = "B"
          elsif(estado == "C")
            opciones[-1][1] = s.partition("@").last.to_i
            @escenas[index].addOption(opciones[-1],[])
            estado = "D"
          else
            errores << "[!] no se esperaba '#{s}' en la línea #{indexl}\n#{line}"
          end
        else
          if(estado=="C")
            opciones[-1][0] << s+" "
          elsif(!estado.match(/-1/) && @escenas.length>0)
            @escenas[index].contenido << s+" "
          end
        end
      end
      estado = estado.delete("-1")
      indexl = indexl + 1
    end
    #ultima escena--------------------------------------------------------------------------------------
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
    #comprobar que no existan bucles
    visitados = {}
    saltosDeterministas.collect do |s|
      visitados[s] = false
    end
    buff = ""
    saltosDeterministas.collect do |s|
      buff << buscaBucles(s,visitados)
      if(buff!="")
        errores << "[!] Bucle formado por las escenas "
        buff.split.map do |m|
          errores << "<#{m}>, "
        end
        errores << "\n"
      end
    end
    if(errores!="")
      errores
    else
      puts "Generadas #{@escenas.length} escenas\n\n"
      true
    end
  end

end
