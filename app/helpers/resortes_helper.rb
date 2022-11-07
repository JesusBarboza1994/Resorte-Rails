module ResortesHelper
  def self.node_coordX(nodeValue, radio)            #Calcula coordenada X del nodo. Entrada: Posicion angular en grados sexagesimales.
    radio * Math.cos(nodeValue * Math::PI / 180)
  end

  def self.node_coordZ (nodeValue, radio)                #Calcula coordenada Z del nodo. Entrada: Posicion angular en grados sexagesimales.
    -radio * Math.sin(nodeValue * Math::PI / 180)
  end

  def self.node_coordY(node_value, nodos_x_vta, resorte, h_extremo1, h_extremo2, h_helice, h_cuerpo)                 #Calcula coordenada Y del nodo. Entrada: Posicion angular en fraccion de vuelta.
    if node_value<=1
      ((node_value*360)**2)/(360*360/h_extremo1)
    elsif node_value>(resorte.vtas.to_f - 1)
      ((node_value*360-resorte.vtas.to_f * 360)**2) / ( 360 * 360 / ( -h_extremo2) ) + h_helice
    elsif node_value>1 && node_value<=(resorte.vtas.to_f - 1)
      inc = h_cuerpo / ((resorte.vtas.to_f - 2) * 360) * 360 / nodos_x_vta
      h_extremo1 + inc * ( node_value*nodos_x_vta-nodos_x_vta)
    end
  end
end
