# coding: utf-8


class Escena
  attr_reader :contenido

  def initialize(contenido, opciones = [])
    @contenido = contenido
    @opciones = opciones
    @salidas = @opciones.map { | op | op[1] }
    # for i in 0..@opciones.size - 1 do
    #   @salidas[i] = @opciones[i][1]
    # end
  end

  def mostrar
    mensaje = @contenido + "\n\n"
    _, result = @opciones.inject([1,""]) { |(count, msg), opcion| msg + "#{count} #{opcion[0].to_s}\n"}
    mensaje += result
    # for i in 0..@opciones.size - 1 do
    #   mensaje = mensaje + "#{i+1} #{@opciones[i][0].to_s}\n"
    # end
    # mensaje
  end

  def entrada(command)  # Cual es el significado del mismo?
    if((command.to_i) - 1 == -1)
      nil
    else
      @salidas[(command.to_i) - 1]
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
end
