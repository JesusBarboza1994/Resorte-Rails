class Resorte < ApplicationRecord
  has_many :points, dependent: :destroy
  include ResortesHelper
  def self.fem(resorte)
    nodos_x_vta = 80 
    elementos = resorte.vtas.to_i*nodos_x_vta
    nodos = elementos + 1 
    radio = (resorte.dext-resorte.diam)/2
    
    ### DIVISIÓN DEL RESORTE EN CUERPO Y EXTREMOS
    @h_helice = resorte.altura-resorte.diam    
    @h_extremo1 = resorte.diam+resorte.luz1
    @h_extremo2 = resorte.diam+resorte.luz2
    @h_cuerpo = @h_helice-@h_extremo1-@h_extremo2
    nodeArray = []
    nodeRadii = []
    nodeTheta = []
    nodeVta = []
    nodos.times do |i|
      nodeArray.push(i)
      nodeTheta.push(i*360/nodos_x_vta)
      nodeVta.push(i/nodos_x_vta)
    end

    nodos.times do |i|
      Point.create(x:node_coordX(nodeTheta[i], radio), y:node_coordY(nodeVta[i],nodos_x_vta), z:node_coordZ(nodeTheta[i], radio), resorte:resorte)
    end


  end

  def node_coordX(nodeValue, radio)            #Calcula coordenada X del nodo. Entrada: Posicion angular en grados sexagesimales.
    x = radio*Math.cos(nodeValue*Math::PI/180)
    return x
  end

  def node_coordZ (nodeValue, radio)                #Calcula coordenada Z del nodo. Entrada: Posicion angular en grados sexagesimales.
    z = -radio*Math.sin(nodeValue*Math::PI/180)
    return z
  end

  def node_coordY(nodeValue, nodos_x_vta)                 #Calcula coordenada Y del nodo. Entrada: Posicion angular en fraccion de vuelta.
    if (nodeValue<=1)
        y = ((nodeValue*360)**2)/(360*360/@h_extremo1)
    elsif (nodeValue>(resorte.vtas-1))
        y = ((nodeValue*360-resorte.vtas*360)**2)/(360*360/(-@h_extremo2))+@h_helice
    elsif (nodeValue>1 && nodeValue<=(resorte.vtas-1))
        inc = @h_cuerpo/((resorte.vtas-2)*360)*360/nodos_x_vta
        y = @h_extremo1 + inc*(nodeValue*nodos_x_vta-nodos_x_vta)
    end
  
    return y
  end
end
