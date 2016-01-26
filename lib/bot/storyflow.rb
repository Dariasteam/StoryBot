# coding: utf-8



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


var = Thread.new "mi_hilo" do |algo|

end
