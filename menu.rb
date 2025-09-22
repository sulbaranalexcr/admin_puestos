menu = Hash.new
menu['Mantenimiento'] = Hash.new
menu['Mantenimiento']['id'] = {"id" => 1, "activo" => true, "tipo" => "ADM/GRP"}
menu['Mantenimiento']['menu'] = []
menu['Mantenimiento']['menu'] << {"id" => 11,"activo" => true,"nombre" => "Cuentas Bancarias","path" => "/cuentas_banca", "seignora" => true, "tipo" => "ADM/GRP"}
menu['Mantenimiento']['menu'] << {"id" => 12,"activo" => false,"nombre" => "Hipodromos","path" => "/hipodromos", "seignora" => true, "tipo" => "ADM"}
menu['Mantenimiento']['menu'] << {"id" => 13,"activo" => true,"nombre" => "Jornadas","path" => "/jornadas", "seignora" => true, "tipo" => "ADM"}
menu['Mantenimiento']['menu'] << {"id" => 14,"activo" => true,"nombre" => "Carreras","path" => "/carreras", "seignora" => true, "tipo" => "ADM"}
menu['Mantenimiento']['menu'] << {"id" => 15,"activo" => true,"nombre" => "Usuarios","path" => "/usuarios", "seignora" => true, "tipo" => "ADM"}


menu['administracion'] = Hash.new
menu['administracion']['id'] = {"id" => 2, "activo" => true, "tipo" => "ADM/GRP"}
menu['administracion']['menu'] = []
menu['administracion']['menu'] << {"id" => 21,"activo" => true,"nombre" => "Grupos","path" => "/grupos", "seignora" => true, "tipo" => "ADM"}
menu['administracion']['menu'] << {"id" => 22,"activo" => true,"nombre" => "Taquillas","path" => "/taquillas", "seignora" => true, "tipo" => "ADM/GRP"}
menu['administracion']['menu'] << {"id" => 23,"activo" => true,"nombre" => "Premiacion","path" => "/premiar", "seignora" => true, "tipo" => "ADM"}
menu['administracion']['menu'] << {"id" => 24,"activo" => true,"nombre" => "Post Time","path" => "/configuracion/posttime", "seignora" => true, "tipo" => "ADM"}
menu['administracion']['menu'] << {"id" => 25,"activo" => true,"nombre" => "Retirar Caballo","path" => "/retirados/index", "seignora" => true, "tipo" => "ADM"}
menu['administracion']['menu'] << {"id" => 26,"activo" => true,"nombre" => "Bloqueo Masivo","path" => "/configuracion/masivo", "seignora" => true, "tipo" => "ADM"}

menu['Deportes'] = Hash.new
menu['Deportes']['id'] = {"id" => 3, "activo" => true, "tipo" => "ADM"}
menu['Deportes']['menu'] = []
menu['Deportes']['menu'] << {"id" => 31,"activo" => true,"nombre" => "Deportes","path" => "/juegos", "seignora" => true, "tipo" => "ADM"}
menu['Deportes']['menu'] << {"id" => 32,"activo" => true,"nombre" => "Ligas","path" => "/ligas", "seignora" => true, "tipo" => "ADM"}
menu['Deportes']['menu'] << {"id" => 33,"activo" => true,"nombre" => "Equipos","path" => "/equipos", "seignora" => true, "tipo" => "ADM"}
menu['Deportes']['menu'] << {"id" => 34,"activo" => true,"nombre" => "Juegos (Match)","path" => "/matchs", "seignora" => true, "tipo" => "ADM"}


menu['Configuracion'] = Hash.new
menu['Configuracion']['id'] = {"id" => 4, "activo" => true, "tipo" => "ADM"}
menu['Configuracion']['menu'] = []
menu['Configuracion']['menu'] << {"id" => 41,"activo" => true,"nombre" => "Reglas Taquilla","path" => "/configuracion/reglas", "seignora" => true, "tipo" => "ADM"}
menu['Configuracion']['menu'] << {"id" => 42,"activo" => true,"nombre" => "Mensaje Taquillas","path" => "/configuracion/mensajes_taquilla", "seignora" => true, "tipo" => "ADM"}


menu['Reportes'] = Hash.new
menu['Reportes']['id'] = {"id" => 5, "activo" => true, "tipo" => "ADM/GRP"}
menu['Reportes']['menu'] = []
menu['Reportes']['menu'] << {"id" => 51,"activo" => true,"nombre" => "Cuadre General","path" => "/reportes/cuadre_general", "seignora" => true, "tipo" => "ADM"}
menu['Reportes']['menu'] << {"id" => 51,"activo" => true,"nombre" => "Cuadre General","path" => "/reportes/cuadre_general_grupo", "seignora" => true, "tipo" => "GRP"}
menu['Reportes']['menu'] << {"id" => 52,"activo" => true,"nombre" => "Premios Ingresados","path" => "/reportes/premios_ingresados_index", "seignora" => true, "tipo" => "ADM/GRP"}
menu['Reportes']['menu'] << {"id" => 52,"activo" => true,"nombre" => "Post Time","path" => "/reportes/posttime", "seignora" => true, "tipo" => "ADM"}
menu['Reportes']['menu'] << {"id" => 53,"activo" => true,"nombre" => "Solicitudes","path" => "/reportes/solicitudes", "seignora" => true, "tipo" => "GRP"}
menu['Reportes']['menu'] << {"id" => 54,"activo" => true,"nombre" => "Movimientos Usuarios","path" => "/reportes/movimientos", "seignora" => true, "tipo" => "GRP"}

MenuUsuario.find_by(user_id: 1,menu: menu.to_json)
