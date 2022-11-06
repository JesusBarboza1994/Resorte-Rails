module ResortesHelper
  def node_coordX(nodeValue, radio)            #Calcula coordenada X del nodo. Entrada: Posicion angular en grados sexagesimales.
    x = radio*Math.cos(nodeValue*Math::PI/180)
    return x
  end
end
