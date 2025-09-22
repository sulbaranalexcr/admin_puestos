# frozen_string_literal: true

# clas para premiacion
class AddPropuestasCaballosJob
  include ApiHelper
  include Sidekiq::Worker

  def perform(args)
  end
end

# corriendo = caballos activos en la carrera
# valor = ml_del_caballo en betfair

# ml = [valor <=6]
# n_favorito = ml.length

# if corriendo = 4
# 	cuadro1
# elsif corriendo = 5
# 	cuadro2
# elsif corriendo >= 6 && n_favoritos >=3
# 	cuadro3
# elsif corriendo >= 6 && n_favoritos =2
# 	cuadro4
# elsif corriendo >= 6 && n_favoritos =1
# 	cuadro5
# end

# #**********************

# def cuadro1

# 	if valor >= 1.3 && valor < 1.4
# 		banquea = 10 a 2
# 		juega = 10 a 5
# 	elsif valor >= 1.4 && valor < 1.5
# 		banquea = 10 a 3
# 		juega = 10 a 6
# 	elsif valor >= 1.5 && valor < 1.6
# 		banquea = 10 a 4
# 		juega = 10 a 7
# 	elsif valor >= 1.6 && valor < 1.7
# 		banquea = 10 a 5
# 		juega = 10 a 8
# 	elsif valor >= 1.7 &&  valor < 1.8
# 		banquea = 10 a 6
# 		juega = 10 a 9
# 	elsif valor >= 1.8 && valor < 1.9
# 		banquea = 10 a 7
# 		juega = P a P
# 	elsif valor >= 1.9 && valor < 2
# 		banquea = 10 a 8
# 		juega = P a P
# 	elsif valor >= 2 && valor < 2.4
# 		banquea = 1P
# 		juega = 2N
# 	elsif valor >= 2.4 && valor < 2.6
# 		banquea = 1 y 2N
# 		juega = 2 y 2N
# 	elsif valor >= 2.6 && valor < 3.1
# 		banquea = 2N
# 		juega = 2P
# 	elsif valor >= 3.1 && valor < 5.5
# 		banquea = 2 y 2N
# 	elsif valor >= 5.5 && valor <= 6
# 		banquea = 2P
# 	end
# 	[juega, banquea]
# end
# #**********************

# def cuadro2

# 	if valor >= 1.2 && valor < 1.3
# 		banquea = 10 a 1
# 		juega = 10 a 3
# 	elsif valor >= 1.3 && valor < 1.4
# 		banquea = 10 a 2
# 		juega = 10 a 4
# 	elsif valor >= 1.4 && valor < 1.5
# 		banquea = 10 a 3
# 		juega = 10 a 5
# 	elsif valor >= 1.5 && valor < 1.6
# 		banquea = 10 a 4
# 		juega = 10 a 6
# 	elsif valor >= 1.6 && valor < 1.7
# 		banquea = 10 a 5
# 		juega = 10 a 7
# 	elsif valor >= 1.7 &&  valor < 1.8
# 		banquea = 10 a 6
# 		juega = 10 a 8
# 	elsif valor >= 1.8 && valor < 1.9
# 		banquea = 10 a 7
# 		juega = 10 a 9
# 	elsif valor >= 1.9 && valor < 2
# 		banquea = 10 a 8
# 		juega = P a P
# 	elsif valor >= 2 && valor < 2.3
# 		banquea = 1P
# 		juega = 2N
# 	elsif valor >= 2.3 && valor < 2.5
# 		banquea = 1 y 2N
# 		juega = 2 y 2N
# 	elsif valor >= 2.5 && valor < 2.9
# 		banquea = 2N
# 		juega = 2P
# 	elsif valor >= 2.9 && valor <= 6
# 		banquea = 2 y 2N
# 		juega = 2 y 3N
# 	end
# end

# #**********************

# def cuadro3

# 	if valor >= 1.2 && valor < 1.3
# 		banquea = 10 a 1
# 		juega = 10 a 3
# 	elsif valor >= 1.3 && valor < 1.4
# 		banquea = 10 a 2
# 		juega = 10 a 4
# 	elsif valor >= 1.4 && valor < 1.5
# 		banquea = 10 a 3
# 		juega = 10 a 5
# 	elsif valor >= 1.5 && valor < 1.6
# 		banquea = 10 a 4
# 		juega = 10 a 6
# 	elsif valor >= 1.6 && valor < 1.7
# 		banquea = 10 a 5
# 		juega = 10 a 7
# 	elsif valor >= 1.7 &&  valor < 1.8
# 		banquea = 10 a 6
# 		juega = 10 a 8
# 	elsif valor >= 1.8 && valor < 1.9
# 		banquea = 10 a 7
# 		juega = 10 a 9
# 	elsif valor >= 1.9 && valor < 2
# 		banquea = 10 a 8
# 		juega = P a P
# 	elsif valor >= 2 && valor < 2.2
# 		banquea = 1P
# 		juega = 2N
# 	elsif valor >= 2.2 && valor < 2.4
# 		banquea = 1 y 2N
# 		juega = 2 y 2N
# 	elsif valor >= 2.4 && valor < 2.5
# 		banquea = 2N
# 		juega = 2P
# 	elsif valor >= 2.5 && valor < 3.1
# 		banquea = 2 y 2N
# 		juega = 2 y 3N
# 	elsif valor >= 3.1 && valor < 3.9
# 		banquea = 2P
# 		juega = 3N
# 	elsif valor >= 3.9 && valor < 4.9
# 		banquea = 2 y 3N
# 	elsif valor >= 4.9 && valor < 5.5
# 		banquea = 3N
# 	elsif valor >= 5.5 && valor <=6
# 		banquea = 3 y 3N
# 	end
# end

# #**********************

# def cuadro4

# 	if valor >= 1.2 && valor < 1.3
# 		banquea = 10 a 1
# 		juega = 10 a 3
# 	elsif valor >= 1.3 && valor < 1.4
# 		banquea = 10 a 2
# 		juega = 10 a 4
# 	elsif valor >= 1.4 && valor < 1.5
# 		banquea = 10 a 3
# 		juega = 10 a 5
# 	elsif valor >= 1.5 && valor < 1.6
# 		banquea = 10 a 4
# 		juega = 10 a 6
# 	elsif valor >= 1.6 && valor < 1.7
# 		banquea = 10 a 5
# 		juega = 10 a 7
# 	elsif valor >= 1.7 &&  valor < 1.8
# 		banquea = 10 a 6
# 		juega = 10 a 8
# 	elsif valor >= 1.8 && valor < 1.9
# 		banquea = 10 a 7
# 		juega = 10 a 9
# 	elsif valor >= 1.9 && valor < 2
# 		banquea = 10 a 8
# 		juega = P a P
# 	elsif valor >= 2 && valor < 2.3
# 		banquea = 1P
# 		juega = 2N
# 	elsif valor >= 2.3 && valor < 2.5
# 		banquea = 1 y 2N
# 		juega = 2 y 2N
# 	elsif valor >= 2.5 && valor < 2.6
# 		banquea = 2N
# 		juega = 2P
# 	elsif valor >= 2.6 && valor < 3.1
# 		banquea = 2 y 2N
# 		juega = 2 y 3N
# 	elsif valor >= 3.1 && valor < 3.9
# 		banquea = 2P
# 		juega = 3N
# 	elsif valor >= 3.9 && valor <= 4.9
# 		banquea = 2 y 3N
# 	end
# end

# #**********************

# def cuadro5

# 	if valor >= 1.3 && valor < 1.4
# 		banquea = 10 a 2
# 		juega = 10 a 5
# 	elsif valor >= 1.4 && valor < 1.5
# 		banquea = 10 a 3
# 		juega = 10 a 6
# 	elsif valor >= 1.5 && valor < 1.6
# 		banquea = 10 a 4
# 		juega = 10 a 7
# 	elsif valor >= 1.6 && valor < 1.7
# 		banquea = 10 a 5
# 		juega = 10 a 8
# 	elsif valor >= 1.7 &&  valor < 1.8
# 		banquea = 10 a 6
# 		juega = 10 a 9
# 	elsif valor >= 1.8 && valor < 1.9
# 		banquea = 10 a 7
# 		juega = P a P
# 	elsif valor >= 1.9 && valor < 2
# 		banquea = 10 a 8
# 		juega = P a P
# 	elsif valor >= 2 && valor < 2.3
# 		banquea = 1P
# 		juega = 2N
# 	elsif valor >= 2.3 && valor < 2.4
# 		banquea = 1 y 2N
# 		juega = 2 y 2N
# 	elsif valor >= 2.4 && valor < 2.7
# 		banquea = 2N
# 		juega = 2P
# 	elsif valor >= 2.7 && valor < 3.9
# 		banquea = 2 y 2N
# 		juega = 2 y 3N
# 	elsif valor >= 3.9 && valor < 5.5
# 		banquea = 2P
# 		juega = 3N
# 	elsif valor >= 5.5 && valor <= 6
# 		banquea = 2 y 3N
# 	end
# end