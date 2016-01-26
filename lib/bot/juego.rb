# coding: utf-8


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
        numero = texto[texto.index('@')+1..-1].to_i  # peta
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

  def self.inicio
    "Envía 'start' para volver a\n"+
      "este menú en cualquier \nmomento\n\n"+
      "1 Jugar historias\n2 Enviar historia\n3 Editar historia"
  end
end
