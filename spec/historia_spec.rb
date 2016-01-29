require 'spec_helper'

describe Historia do
  before :all do
    @historia = nil
  end

  it 'ejemplo de historia' do
    expect(Historia.ejemplo.is_a? String).to eq true
  end

  it 'carga de la historia' do
    @historia = Historia.from_string(Historia.ejemplo)
    expect(@historia.is_a? Historia).to eq true
  end

  it 'guardarEscena' do
    # TODO: es complicado ver que hacer
  end

  describe "Parser de Historias" do
    before :all do
      # TODO: trabajar en ello
    end
    # Modularizar el parser en secciones para testearlas correctamente
    # Testear tambien el conjunto entero
  end
end
