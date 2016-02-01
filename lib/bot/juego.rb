# coding: utf-8
require "bot/historia"

# esta clase no tiene gran significado en si solo hace de wrapper de historia
# historia deberia tener los metodos de mostrar reniciar...
class Juego                                  #Uno por jugador, emplea la información de la clase Historia

  def initialize(historia)
    @escenas = historia.escenas
    @actual = @escenas[0]
  end

  def entrada(command)
    if(@actual!=nil)
      aux = @actual.entrada(command)
      if(aux!=nil)
        @actual = @escenas[aux]
      else
        nil
      end
    end
  end

  def mostrar
    if(@actual!= nil)
      texto = @actual.mostrar
      while(texto[0].include?("@"))
        numero = texto[0][texto[0].index('@')+1..-1].to_i  # peta
        texto[0] = texto[0][0..texto[0].index('@')-1]
        @actual = @escenas[numero]
        texto[0] << "\n#{@actual.mostrar[0]}"
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

  def self.inicio  # Momentaneo -> to ServerBot
    "Envía '/start' para volver a\n"+
      "este menú en cualquier \nmomento\n\n"+
      "1 Jugar historias\n2 Enviar historia\n3 Editar historia"
  end
end
