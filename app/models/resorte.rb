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
    elemX=[]
    elemY=[]
    elemZ=[]
    long=[]

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
        elemX.push( Point.find(ii+2).x - Point.find(ii+1).x )
        elemY.push( Point.find(ii+2).y - Point.find(ii+1).y )
        elemZ.push( Point.find(ii+2).z - Point.find(ii+1).z)
        long.push(( elemX[ii]**2 + elemY[ii]**2 + elemZ[ii]**2)**0.5)
        #Unitario direccion axial (x)
        unit_xX.push(elemX[ii] / long[ii])
        unit_xY.push(elemY[ii] / long[ii])
        unit_xZ.push(elemZ[ii] / long[ii])

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
        phi_z = 12*youngModulus*inercia/(kappa*shearModulus*area*long[ii]**2)
        phi_y = 12*youngModulus*inercia/(kappa*shearModulus*area*long[ii]**2)
        phi_bar_z = 1/(1+phi_z)
        phi_bar_y = 1/(1+phi_y)

        k1 = youngModulus*area/long[ii]
        k2 = 12*phi_bar_z*youngModulus*inercia/long[ii]**3
        k3 = 6*phi_bar_z*youngModulus*inercia /long[ii]**2
        k4 = 12*phi_bar_y*youngModulus*inercia/long[ii]**3
        k5 = 6*phi_bar_y*youngModulus*inercia /long[ii]**2
        k6 = shearModulus*inerciapolar/long[ii]
        k7 = (4+phi_y)*phi_bar_y*youngModulus*inercia/long[ii]
        k8 = (4+phi_z)*phi_bar_z*youngModulus*inercia/long[ii]
        k9 = (2-phi_y)*phi_bar_y*youngModulus*inercia/long[ii]
        k10 = (2-phi_z)*phi_bar_z*youngModulus*inercia/long[ii]

        #Creacion de la matriz vacia de rigidez 12x12
        matrizRigLocal = Matrix.zero(12)
              
        #Asignacion de los elementos a la matriz
        matrizRigLocal[0,0]  = k1
        matrizRigLocal[6,0]  = -k1
        matrizRigLocal[1,1]  = k2
        matrizRigLocal[5,1]  = k3
        matrizRigLocal[7,1]  = -k2
        matrizRigLocal[11,1] = k3
        matrizRigLocal[2,2]  = k4
        matrizRigLocal[4,2]  = -k5
        matrizRigLocal[8,2]  = -k4
        matrizRigLocal[10,2] = -k5
        matrizRigLocal[3,3]  = k6
        matrizRigLocal[9,3]  = -k6
        matrizRigLocal[2,4]  = -k5
        matrizRigLocal[4,4]  = k7
        matrizRigLocal[8,4]  = k5
        matrizRigLocal[10,4] = k9
        matrizRigLocal[1,5]  = k3
        matrizRigLocal[5,5]  = k8
        matrizRigLocal[7,5]  = -k3
        matrizRigLocal[11,5] = k10
        matrizRigLocal[0,6]  = -k1
        matrizRigLocal[6,6]  = k1
        matrizRigLocal[1,7]  = -k2
        matrizRigLocal[5,7]  = -k3
        matrizRigLocal[7,7]  = k2
        matrizRigLocal[11,7] = -k3
        matrizRigLocal[2,8]  = -k4
        matrizRigLocal[4,8]  = k5
        matrizRigLocal[8,8]  = k4
        matrizRigLocal[10,8] = k5
        matrizRigLocal[3,9]  = -k6
        matrizRigLocal[9,9]  = k6
        matrizRigLocal[2,10] = -k5
        matrizRigLocal[4,10] = k9
        matrizRigLocal[8,10] = k5
        matrizRigLocal[10,10]= k7
        matrizRigLocal[1,11] = k3
        matrizRigLocal[5,11] = k10
        matrizRigLocal[7,11] = -k3
        matrizRigLocal[11,11]= k8

        #Matriz Vacia de transformacion de coordenadas local a global
        matrizTransCoord = Matrix.zero(12)
        
        #Asignacion de los cosenos directores a la matriz de transformacion
        4.times do |u|
          matrizTransCoord[0+3*u,0+3*u] = unit_xX[ii]
          matrizTransCoord[0+3*u,1+3*u] = unit_xY[ii]
          matrizTransCoord[0+3*u,2+3*u] = unit_xZ[ii]
          matrizTransCoord[1+3*u,0+3*u] = unit_yX[ii]
          matrizTransCoord[1+3*u,1+3*u] = unit_yY[ii]
          matrizTransCoord[1+3*u,2+3*u] = unit_yZ[ii]
          matrizTransCoord[2+3*u,0+3*u] = unit_zX[ii]
          matrizTransCoord[2+3*u,1+3*u] = unit_zY[ii]
          matrizTransCoord[2+3*u,2+3*u] = unit_zZ[ii]
        end

        #Almacenar matriz de rigidez del elemento
        vectorKlocal.push(matrizRigLocal.to_a)
        #Almacenar Matriz de transformacion del elemento
        vectorT.push(matrizTransCoord.to_a)
        vectorTprime.push((matrizTransCoord).transpose.to_a)
        #Calculo de la matriz de rigidez global
        firstProd = []
        matrizRigGlobal = []
        firstProd.push((matrizTransCoord.transpose * matrizRigLocal).to_a)
        binding.pry
        matrizRigGlobal.push((Matrix[*firstProd] * matrizTransCoord).to_a)
        #Almacenar matriz de rigidez global del elemento
        vectorKGlobal.push(matrizRigGlobal)
      end
    end
    #FIN FOR DE OPERACIONES POR ELEMENTO
    #Crear la supermatriz de rigidez del solido
    superMatrix = Matrix.zero(nodos*6+18).to_a
    #Numero de filas de la supermatriz de rigidez: #Nodos * Grados de libertad de cada nodo (son 6 en 3D). Se suman 18 filas más para las condic. contorno
 
    #Incorporar las matrices de rigidez global de cada elemento a la matriz.
    vectorKGlobal.length.times do |p|
      matrix = vectorKGlobal[p][0][0]
      superMatrix = ResortesHelper::sumMatrix(superMatrix,matrix,(p)*6,(p)*6)
    end
    #Utilización de las condiciones de contorno.
    3.times do |q|
      #UX, UY, UZ de los nodos de la base
      superMatrix[nodos*6 + q + 0][(lownode1)*6+q] = 1
      superMatrix[nodos*6 + q + 3][(lownode2)*6+q] = 1
      superMatrix[nodos*6 + q + 6][(lownode3)*6+q] = 1

      #UX, UY, UZ de los nodos del tope
      superMatrix[nodos*6 + q + 9][(upnode1)*6+q] = 1
      superMatrix[nodos*6 + q + 12][(upnode2)*6+q] = 1
      superMatrix[nodos*6 + q + 15][(upnode3)*6+q] = 1

      #FX, FY, FZ de los nodos de la base
      superMatrix[(lownode1)*6+q][nodos*6 + q] = -1
      superMatrix[(lownode2)*6+q][nodos*6 + q + 3] = -1
      superMatrix[(lownode3)*6+q][nodos*6 + q + 6] = -1
    
      #FX, FY, FZ de los nodos del tope
      superMatrix[(upnode1)*6+q][nodos*6 + q + 9] = -1
      superMatrix[(upnode2)*6+q][nodos*6 + q + 12] = -1
      superMatrix[(upnode3)*6+q][nodos*6 + q + 15] = -1 
    end

    #CONFIGURACION DE LA SIMULACION

    #Almacenes de resultados
    storeForces = [] #Almacena matrices de 6 filas (6 nodos BC) x 3 columnas (X,Y,Z)
    storeDispl = [] #Almacena matrices de despl. con filas=Total de nodos y 6 columnas (Despl. Traslacional XYZ y Angular XYZ)
    storeStress= [] #Almacena datos de esfuerzos
    storeSummary = []

    storeForceSum = [] #Vector con la fuerza de reaccion en KG de cada simulacion.
    storevmuy     = []
    storevmdz     = []
    storevmdy     = []
    storevmuz     = []
    storecuy      = []
    storecdz      = []
    storecdy      = []
    storecuz      = []

    deltaY = 0
    ##Iteracion de simulaciones!
    6.times do |jj|
      deltaY = -25-jj*25
  
      #Vector de coeficientes independientes:
      coef = []
      superMatrix.length.times do |pp|
        coef.push([0])
      end
  
      coef[coef.length-8]=[deltaY]
      coef[coef.length-5]=[deltaY]
      coef[coef.length-2]=[deltaY]
      
      #Calculo de la inversa = el vector solucion de desplazamientos y fuerzas "solut"
      inverse = Matrix[*superMatrix].inverse
      solut = (Matrix[*inverse] * Matrix[*coef]).to_a

      #Matriz de desplazamientos!
      displaceMatrix = []
      w=0
      nodos.times do |v|
        displaceVect=[]
        6.times do |vv|
            displaceVect.push(solut[w][0])
            w=w+1
        end
        displaceMatrix.push(displaceVect)
      end

      #Matriz de fuerzas en los nodos de las condiciones de contorno
      forceMatrix = []
      6.times do |vv| #Son 6 nodos de las condiciones de contorno. Esta matriz tendra 6 filas. 
        forceVect = []
        3.times do |uv| #Cada fila tendra las fuerzas X,Y,Z de los nodos (3 columnas)
          forceVect.append(solut[w][0])
          w = w+1
        end
        forceMatrix.append(forceVect)
      end

      forceSum = (forceMatrix[0][1] + forceMatrix[1][1] + forceMatrix[2][1])/9.81
      storeForceSum.append(forceSum) 

      #Vector de desplazamientos POR ELEMENTO
      dispLoc = []
      dispGlob = []
      nodos.times do |nn|
        if nn !=nodos_x_vta*resorte.vtas
            dispGlob.push(displaceMatrix[nn]+displaceMatrix[nn+1])
        end
      end

      nodos.times do |mm|
        if mm !=nodos_x_vta*resorte.vtas
          dispglob1 = dispGlob[mm]
          dispLoc.push((Matrix[*vectorT[mm]] * Matrix[*dispglob1].transpose).to_a)
        end
      end
      
      storeForces.push(forceMatrix)
      storeDispl.push(displaceMatrix)

      p storeForces
    end
  end
end
