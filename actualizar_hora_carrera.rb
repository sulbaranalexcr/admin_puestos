def actualizar_hora_carre(cantidad)
    Carrera.where(created_at: Time.now.all_day).each {|carr|
    hora1 = (carr.hora_carrera.to_time - cantidad.hour).strftime("%H:%M:%S")
    hora2 = (carr.hora_pautada.to_time - cantidad.hour).strftime("%H:%M:%S")
    carr.update(hora_carrera: hora1, hora_pautada: hora2)
    }
end