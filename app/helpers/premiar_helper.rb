module PremiarHelper
  def buscar_datos_taquilla(taq_id, carrera_id, taq_comision, grupo_id, cobrador_id, tipo)
    monto_divide2 = 0
    venta1 = 0
    venta2 = 0
    total_premio = 0
    total_comision = 0
    quien_recibe = 0
    gano_grupo = 0
    comision_grupo = 0
    if tipo.to_i == 1
      pre2 = PremiacionCaballosPuesto.where(id_gana: taq_id, carrera_id: carrera_id)
    else
      pre2 = Premiacion.where(id_gana: taq_id, carrera_id: carrera_id)
    end
    pre2.each { |pre_temp2|
      if UsuariosTaquilla.where(id: [pre_temp2.id_quien_juega, pre_temp2.id_quien_banquea]).pluck(:cobrador_id).group_by { |i| i }.count > 1
        if pre_temp2.id_quien_juega.to_i == pre_temp2.id_gana.to_i
          quien_recibe = pre_temp2.id_quien_banquea
        else
          quien_recibe = pre_temp2.id_quien_juega
        end
        monto_divide2 += (pre_temp2.monto_pagado_completo.to_f / 2)
        comis_temp = ((pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100) / 2
        if taq_id.to_i == pre_temp2.id_gana.to_i
          @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
          @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
          @estruc_2["T#{taq_id.to_s}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
          @estruc_2["T#{quien_recibe}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
        else
          @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
          @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
          @estruc_2["T#{taq_id.to_s}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
          @estruc_2["T#{quien_recibe}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
        end
        @estruc_2["T#{taq_id.to_s}"]["comision_oc"] += comis_temp
        @estruc_2["T#{quien_recibe}"]["comision_oc"] += comis_temp
      else
        total_premio += pre_temp2.monto_pagado_completo.to_f
        total_comision += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
      end
      gano_grupo += pre_temp2.monto_pagado_completo.to_f
      comision_grupo += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
    }
    @estruc_2["T#{taq_id.to_s}"]["venta"] += venta1 + venta2
    @estruc_2["T#{taq_id.to_s}"]["premio"] += total_premio
    @estruc_2["T#{taq_id.to_s}"]["comision"] += total_comision

    @estruc_2["G#{grupo_id.to_s}"]["venta"] += venta1.to_f + venta2.to_f
    @estruc_2["G#{grupo_id.to_s}"]["premio"] += gano_grupo
    @estruc_2["G#{grupo_id.to_s}"]["comision"] += comision_grupo
    if @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i > 0
      onid = @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i
      @estruc_2["I#{onid.to_s}"]["venta"] += venta1.to_f + venta2.to_f
      @estruc_2["I#{onid.to_s}"]["premio"] += gano_grupo
      @estruc_2["I#{onid.to_s}"]["comision"] += comision_grupo
    end
  end

  def generar_reportes_puestos(tipo, id_carrera, ids_dia,fecha_hora)
    hipodromo_id_bus = Carrera.find(id_carrera).jornada.hipodromo.id
    @estruc_1 = Hash.new
    @estruc_2 = Hash.new
    @objeto_inter = Hash.new
    intermediarios = Intermediario.all
    intermediarios.each { |inter|
      @objeto_inter["#{inter.id.to_s}"] = { "id" => inter.id, "porcentaje_banca" => inter.porcentaje_banca }
      @estruc_2["I#{inter.id.to_s}"] = { "id" => inter.id, "venta" => 0, "premio" => 0, "gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
    }
    @objeto_grupo = Hash.new
    grupos = Grupo.all
    if grupos.present?
      grupos.each { |grp|
        @objeto_grupo["#{grp.id.to_s}"] = { "id" => grp.id, "inter_id" => grp.intermediario_id, "porcentaje_banca" => grp.porcentaje_banca, "porcentaje_intermediario" => grp.porcentaje_intermediario }
        @estruc_2["G#{grp.id.to_s}"] = { "id" => grp.id, "venta" => 0, "premio" => 0, "gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
      }
    end

    taquillas = UsuariosTaquilla.select(:id, :grupo_id, :comision, :cobrador_id).where(id: ids_dia)
    taquillas.each { |taq|
      @estruc_2["T#{taq.id.to_s}"] = {
        "id" => taq.id,
        "venta" => 0,
        "premio" => 0,
        "gano_oc" => 0,
        "perdio_oc" => 0,
        "comision" => 0,
        "comision_oc" => 0,
        "moneda" => 2,
        "comis_taq" => taq.comision.to_f,
        "monto_otro_grupo" => 0,
      }
    }
    taquillas.each { |taq|
      datos = buscar_datos_taquilla(taq.id, id_carrera, 5, taq.grupo_id, taq.cobrador_id, tipo)
    }

    estructuras = Estructura.where.not(tipo: 5)
    estructuras.each { |est|
      venta2 = 0
      premio2 = 0
      comision2 = 0
      tipo_est = ""
      case est.tipo.to_i
      when 2
        tipo_est = "I"
      when 3
        tipo_est = "G"
      when 4
        tipo_est = "T"
        # when 5
        #   tipo_est = "C"
      end
      if est.tipo.to_i == 4 and ids_dia.include?(est.tipo_id) or est.tipo.to_i != 4
        venta = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f
        premio = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["premio"].to_f
        comision = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision"].to_f
        gano_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["gano_oc"].to_f
        perdio_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["perdio_oc"].to_f
        comision_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision_oc"].to_f
        momto_cobranza2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["monto_otro_grupo"].to_f
        if tipo.to_i == 1
          CuadreGeneralCaballosPuesto.create(estructura_id: est.id, venta: venta, premio: premio, gano_oc: gano_oc, perdio_oc: perdio_oc, comision: comision, comision_oc: comision_oc, utilidad: 0, moneda: 2, carrera_id: id_carrera, hipodromo_id: hipodromo_id_bus, monto_otro_grupo: momto_cobranza2, created_at: fecha_hora)
        else
          CuadreGeneralCaballosLogro.create(estructura_id: est.id, venta: venta, premio: premio, gano_oc: gano_oc, perdio_oc: perdio_oc, comision: comision, comision_oc: comision_oc, utilidad: 0, moneda: 2, carrera_id: id_carrera, hipodromo_id: hipodromo_id_bus, monto_otro_grupo: momto_cobranza2, created_at: fecha_hora)
        end
      end
    }
  end






  def buscar_datos_taquilla_deportes(taq_id, match_id, taq_comision, grupo_id, cobrador_id)
    monto_divide2 = 0
    venta1 = 0
    venta2 = 0
    total_premio = 0
    total_comision = 0
    quien_recibe = 0
    gano_grupo = 0
    comision_grupo = 0
    pre2 = PremiacionDeporte.where(id_gana: taq_id, match_id: match_id)
    pre2.each { |pre_temp2|
      if UsuariosTaquilla.where(id: [pre_temp2.id_quien_juega, pre_temp2.id_quien_banquea]).pluck(:cobrador_id).group_by { |i| i }.count > 1
        if pre_temp2.id_quien_juega.to_i == pre_temp2.id_gana.to_i
          quien_recibe = pre_temp2.id_quien_banquea
        else
          quien_recibe = pre_temp2.id_quien_juega
        end
        monto_divide2 += (pre_temp2.monto_pagado_completo.to_f / 2)
        comis_temp = ((pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100) / 2
        if taq_id.to_i == pre_temp2.id_gana.to_i
          @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
          @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
          @estruc_2["T#{taq_id.to_s}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
          @estruc_2["T#{quien_recibe}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
        else
          @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
          @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
          @estruc_2["T#{taq_id.to_s}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
          @estruc_2["T#{quien_recibe}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
        end
        @estruc_2["T#{taq_id.to_s}"]["comision_oc"] += comis_temp
        @estruc_2["T#{quien_recibe}"]["comision_oc"] += comis_temp
      else
        total_premio += pre_temp2.monto_pagado_completo.to_f
        total_comision += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
      end
      gano_grupo += pre_temp2.monto_pagado_completo.to_f
      comision_grupo += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
    }
    @estruc_2["T#{taq_id.to_s}"]["venta"] += venta1 + venta2
    @estruc_2["T#{taq_id.to_s}"]["premio"] += total_premio
    @estruc_2["T#{taq_id.to_s}"]["comision"] += total_comision

    @estruc_2["G#{grupo_id.to_s}"]["venta"] += venta1.to_f + venta2.to_f
    @estruc_2["G#{grupo_id.to_s}"]["premio"] += gano_grupo
    @estruc_2["G#{grupo_id.to_s}"]["comision"] += comision_grupo
    if @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i > 0
      onid = @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i
      @estruc_2["I#{onid.to_s}"]["venta"] += venta1.to_f + venta2.to_f
      @estruc_2["I#{onid.to_s}"]["premio"] += gano_grupo
      @estruc_2["I#{onid.to_s}"]["comision"] += comision_grupo
    end
  end

  def generar_reportes_deporte(deporte_id,match_id, ids_dia,fecha_hora)
    @estruc_1 = Hash.new
    @estruc_2 = Hash.new
    @objeto_inter = Hash.new
    intermediarios = Intermediario.all
    intermediarios.each { |inter|
      @objeto_inter["#{inter.id.to_s}"] = { "id" => inter.id, "porcentaje_banca" => inter.porcentaje_banca }
      @estruc_2["I#{inter.id.to_s}"] = { "id" => inter.id, "venta" => 0, "premio" => 0, "gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
    }
    @objeto_grupo = Hash.new
    grupos = Grupo.all
    if grupos.present?
      grupos.each { |grp|
        @objeto_grupo["#{grp.id.to_s}"] = { "id" => grp.id, "inter_id" => grp.intermediario_id, "porcentaje_banca" => grp.porcentaje_banca, "porcentaje_intermediario" => grp.porcentaje_intermediario }
        @estruc_2["G#{grp.id.to_s}"] = { "id" => grp.id, "venta" => 0, "premio" => 0, "gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
      }
    end

    taquillas = UsuariosTaquilla.select(:id, :grupo_id, :comision, :cobrador_id).where(id: ids_dia)
    taquillas.each { |taq|
      @estruc_2["T#{taq.id.to_s}"] = {
        "id" => taq.id,
        "venta" => 0,
        "premio" => 0,
        "gano_oc" => 0,
        "perdio_oc" => 0,
        "comision" => 0,
        "comision_oc" => 0,
        "moneda" => 2,
        "comis_taq" => 5,
        "monto_otro_grupo" => 0,
      }
    }
    taquillas.each { |taq|
      datos = buscar_datos_taquilla_deportes(taq.id, match_id, 5, taq.grupo_id, taq.cobrador_id)
    }

    estructuras = Estructura.where.not(tipo: 5)
    estructuras.each { |est|
      venta2 = 0
      premio2 = 0
      comision2 = 0
      tipo_est = ""
      case est.tipo.to_i
      when 2
        tipo_est = "I"
      when 3
        tipo_est = "G"
      when 4
        tipo_est = "T"
        # when 5
        #   tipo_est = "C"
      end
      if est.tipo.to_i == 4 and ids_dia.include?(est.tipo_id) or est.tipo.to_i != 4
        venta = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f
        premio = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["premio"].to_f
        comision = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision"].to_f
        gano_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["gano_oc"].to_f
        perdio_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["perdio_oc"].to_f
        comision_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision_oc"].to_f
        momto_cobranza2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["monto_otro_grupo"].to_f
          CuadreGeneralDeporte.create(estructura_id: est.id, venta: venta, premio: premio, gano_oc: gano_oc, perdio_oc: perdio_oc, comision: comision, comision_oc: comision_oc, utilidad: 0, moneda: 2, juego_id: deporte_id, match_id: match_id, monto_otro_grupo: momto_cobranza2, created_at: fecha_hora)
      end
    }
  end


end

