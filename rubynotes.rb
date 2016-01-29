# coding: utf-8


<<<<<<< HEAD
=begin
Seguramente hace falta pa algo las siguientes cosas:
- clone y dup: hacen una copia superficial del objeto

  + DUP: Produces a shallow copy of obj—the instance variables of obj are copied,
    but not the objects they reference. *dup copies the tainted state of obj*.
    This method may have class-specific behavior. If so, that behavior will
    be documented under the #initialize_copy method of the class.

on dup vs clone

In general, clone and dup may have different semantics in descendant classes.
While clone is used to duplicate an object, including its internal state,
dup typically uses the class of the descendant object to create the new instance.

   + CLONE: Produces a shallow copy of obj—the instance variables of obj are copied, but not
     the objects they reference. clone copies the frozen and tainted state of obj.


clone: copia  el estado del objeto → frozen? y tain
freeze: congela el objeto no se puede modificar
taint: Es un estado de manchado. Sirve para  confirmar un posible codigo malisioso
dup: solo copia el estado de manchado

Se define initialize_copy(*origin)
para generar una copia del objeto

marshal_dump y marshal_load permiten serializar el objeto y desserializarlo

=end

=======
>>>>>>> dani/master
class Ejemplo
  private_class_method :new

  def initialize str
    puts str
  end

  def self.ejemplo *args
    object = new *args
    object
  end
end



var = Thread.new "mi_hilo" do |algo|

end

fiber = Fiber.new do |hey|
  puts "1#{hey}"
  hey = Fiber.yield
  puts "2#{hey}"
  hey = Fiber.yield
  puts "3#{hey}"
  hey = Fiber.yield
  puts "4#{hey}"
end


class StoryFlow
  attr_accessor :pointer

  def initialize &block
    instance_eval(&block)
  end

  def method_missing(name, *args, &block)
    if @pointer.nil?
      @pointer = name.to_sym
    end
    definition = proc do |option|
      # TODO guardar el texto en cada funcion ver como
      args[1][option]
    end
    self.class.send(:define_method, name, definition)
  end

  def step option
    result = send(@pointer,option)
    if not result.nil?
      @pointer = result
    end
  end
end

m = StoryFlow.new do
  inicio "Erase una vez..."
  0 => :fin,
  1 => :interminable,
  2 => :inicio

  interminable "Una historia ¬ terminable"
  0 => :interminable

  fin "Terminable"
  0 => :fin
end


class App
  private
  def method
    puts "hola"
  end
  # private :method # ponerlo antes del metodo no sirve
end

class Game < App
  def initialize
    self.method
  end
end
