class Resorte < ApplicationRecord
  has_many :points, dependent: :destroy
  def self.fem(resorte)
    nodos_x_vta = 80
    elementos = resorte.vtas.to_f * nodos_x_vta
    nodos = (elementos + 1).to_i
    radio = (resorte.dext.to_f - resorte.diam.to_f) / 2
    ### DIVISIÓN DEL RESORTE EN CUERPO Y EXTREMOS
    @h_helice = resorte.altura.to_f - resorte.diam.to_f
    @h_extremo1 = resorte.diam.to_f + resorte.luz1.to_f
    @h_extremo2 = resorte.diam.to_f + resorte.luz2.to_f
    @h_cuerpo = @h_helice - @h_extremo1 - @h_extremo2
    nodeArray = []
    nodeTheta = []
    nodeVta = []
    nodos.times do |i|
      nodeArray.push(i)
      nodeTheta.push(i*360/nodos_x_vta)
      nodeVta.push(i/nodos_x_vta)
    end

    ### PROPIEDADES DEL MATERIAL DEL RESORTE 
    youngModulus = 206700 #en MPa
    shearModulus = 79500; #en MPa

    ### CONDICIONES DE CONTORNO 
    lownode1 =  14  #10     #2         #
    lownode2 =  39  #35     #11        #
    lownode3 =  64 #60     #20        #
    upnode1 = 575 #790 #740    #222       #
    upnode2 = 600 #793 #765    #231       #
    upnode3 = 625 #796 #790    #240       #

    area = 0.25*Math::PI*resorte.diam.to_f**2 #en mm2
    inercia = 0.25*Math::PI*(resorte.diam.to_f/2**4) #en mm4
    inerciapolar = inercia*2 
    nodos.times do |i|
      Point.create(x: ResortesHelper::node_coordX(nodeTheta[i], radio), y: ResortesHelper::node_coordY(nodeVta[i],nodos_x_vta,resorte, @h_extremo1, @h_extremo2, @h_helice, @h_cuerpo), z: ResortesHelper::node_coordZ(nodeTheta[i], radio), resorte:resorte)
    end

    #Declarar las dimensiones XYZ de cada elemento viga
    ElemX=[]
    ElemY=[]
    ElemZ=[]
    Long=[]

    #Declarar vectores unitarios axial(x), transversal(z) y vertical(y) del elemento
    unit_xX = [] 
    unit_zX = []
    unit_yX = []
    unit_xY = [] 
    unit_zY = []
    unit_yY = []
    unit_xZ = [] 
    unit_zZ = []
    unit_yZ = []

    #Declarar angulos entre ejes locales (xyz) y globales(XYZ) del elemento
    ang_xX = []
    ang_zX = [] 
    ang_yX = []
    ang_xY = []
    ang_zY = [] 
    ang_yY = []
    ang_xZ = []
    ang_zZ = [] 
    ang_yZ = []
    #Declarar vectores acumuladores de matrices
    vectorKlocal = []
    vectorT = []
    vectorTprime = []
    vectorKGlobal=[]

    #OPERACIONES POR ELEMENTO   
    nodos.times do |ii|
      if ii != nodos_x_vta * resorte.vtas
        #Direccion de los elementos
        ElemX.push( Point.find(ii+2).x - Point.find(ii+1).x )
        
        ElemY.push( Point.find(ii+2).y - Point.find(ii+1).y )
        
        ElemZ.push( Point.find(ii+2).z - Point.find(ii+1).z)
        Long.push(( ElemX[ii]**2 + ElemY[ii]**2 + ElemZ[ii]**2)**0.5)
        #Unitario direccion axial (x)
        unit_xX.push(ElemX[ii] / Long[ii])
        unit_xY.push(ElemY[ii] / Long[ii])
        unit_xZ.push(ElemZ[ii] / Long[ii])

        #Unitario direccion transversal (z)
        unit_zX.push(-unit_xZ[ii]/(unit_xZ[ii]).abs * (unit_xZ[ii]**2 /(unit_xZ[ii]**2 + unit_xX[ii]**2))**0.5)
        unit_zY.push(0)
        unit_zZ.push(unit_xX[ii] / (unit_xX[ii]).abs * (unit_xX[ii]**2 / (unit_xZ[ii]**2 + unit_xX[ii]**2))**0.5)
                
        #Unitario direccion vertical (y)
        unit_yX.push(unit_xZ[ii] * unit_zY[ii] - unit_xY[ii] * unit_zZ[ii])
        unit_yY.push(unit_xX[ii] * unit_zZ[ii] - unit_xZ[ii] * unit_zX[ii])
        unit_yZ.push(-(unit_xX[ii] * unit_zY[ii] - unit_xY[ii] * unit_zX[ii]))

        #Angulos ejes locales (xyz) vs ejes globales (XYZ)

        #Angulos del eje local x con los globales XYZ
        ang_xX.push(Math.acos(unit_xX[ii])*180/Math::PI)
        ang_xY.push(Math.acos(unit_xY[ii])*180/Math::PI)
        ang_xZ.push(Math.acos(unit_xZ[ii])*180/Math::PI)

        #Angulos del eje local z con los globales XYZ
        ang_zX.push(Math.acos(unit_zX[ii])*180/Math::PI)
        ang_zY.push(Math.acos(unit_zY[ii])*180/Math::PI)
        ang_zZ.push(Math.acos(unit_zZ[ii])*180/Math::PI)
        
        #Angulos del eje local y con los globales XYZ
        ang_yX.push(Math.acos(unit_yX[ii])*180/Math::PI)
        ang_yY.push(Math.acos(unit_yY[ii])*180/Math::PI)
        ang_yZ.push(Math.acos(unit_yZ[ii])*180/Math::PI)

        #Elementos de la matriz de rigidez

        kappa = 0.886
        phi_z = 12*youngModulus*inercia/(kappa*shearModulus*area*Long[ii]**2)
        phi_y = 12*youngModulus*inercia/(kappa*shearModulus*area*Long[ii]**2)
        phi_bar_z = 1/(1+phi_z)
        phi_bar_y = 1/(1+phi_y)

        k1 = youngModulus*area/Long[ii]
        k2 = 12*phi_bar_z*youngModulus*inercia/Long[ii]**3
        k3 = 6*phi_bar_z*youngModulus*inercia /Long[ii]**2
        k4 = 12*phi_bar_y*youngModulus*inercia/Long[ii]**3
        k5 = 6*phi_bar_y*youngModulus*inercia /Long[ii]**2
        k6 = shearModulus*inerciapolar/Long[ii]
        k7 = (4+phi_y)*phi_bar_y*youngModulus*inercia/Long[ii]
        k8 = (4+phi_z)*phi_bar_z*youngModulus*inercia/Long[ii]
        k9 = (2-phi_y)*phi_bar_y*youngModulus*inercia/Long[ii]
        k10 = (2-phi_z)*phi_bar_z*youngModulus*inercia/Long[ii]
  end
end
