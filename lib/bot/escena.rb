# coding: utf-8


class Escena
  attr_reader :contenido
  attr_accessor :probabilistico, :contenido

  def initialize
    @contenido = ""
    @opciones = []
    @salidas = {}
    @probabilistico = []
  end

  def mostrar
    if(@probabilistico == [])
      mensaje = @contenido + "\n\n"
      for i in 0..@opciones.size - 1 do
        mensaje = mensaje + "#{i+1} #{@opciones[i][0].to_s}\n"
      end
    else
      mensaje = @contenido.sub(/@\d/,"")
      p = rand(1..@probabilistico[0])
      i = 1
      while @probabilistico[i][1] < p
        i = i + 1
      end
      mensaje << "@#{@probabilistico[i][2]}"
    end
    mensaje
  end

  def addOption(option,probabilistico = [])
    if(probabilistico == [])
      @opciones << option
      @salidas[@salidas.size] = option[1]
    else
      @opciones << [option,probabilistico]
    end
  end
  def addProb(probabilistico = [])
    @probabilistico << probabilistico
  end

  def entrada(command)
    if((command.to_i-1 == -1 )||(command.to_i-1 > (@opciones.size-1) ))
      nil
    else
      if(@opciones[command.to_i-1][1].kind_of?(Array))
        probabilistico = @opciones[command.to_i-1][1]
        p = rand(1..probabilistico[0])
        i = 1
        while probabilistico[i][1] < p
          i = i + 1
        end
        probabilistico[i][2]
      else
        @salidas[(command.to_i) - 1]
      end
    end
  end

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
#end
