App.web_notifications_banca = App.cable.subscriptions.create("WebNotificationsBancaChannel", {
connected: function() {
    console.log('Conectado al canal.');
  },

  disconnected: function() {
    console.log('Desconectado del canal.');
  },

  received: function(data) {
     if (data.data.tipo == 'REFRESH_POR_TIPO') {
      eliminarOptionPorValor(data.data.id)
     }  
     if (data.data.tipo == 0){
       if (data.data.procesa == window.usuario_id){
         return
       }
       index = data_chats.chats.findIndex(x => x.id == data.data.chat_id);
       if (index != -1){
         data_chats.chats.splice(index, 1);
       }
      //  data_chats.chats = data_chats.chats.filter(x => x.id != data.data.chat_id);
     }
     if (data.data.tipo == 998877){
       remove_race_auto(data.data.id)
     }
     if (data.data.tipo == 1) {
        notificar_premiacion();
     }
     if (data.data.tipo == 2) {
        cerrar_notificar_premiacion();
     }
     if (data.data.tipo == 400) {
       $("#boton_enviar_match").attr("disabled", false);
       swal("Error", data.data.msg, "error");
     }
    if (data.data.tipo == 2500) {
      if (window.tipo_user == "ADM"){
        datos = data.data.data ;
        $('#marquesina_superior').show();
        marquesina_superior.start();
        $('#carreras_premiar').append(`<option value="${datos.id}">${datos.carrera} (${datos.hipodromo})</option>`);
        let src = '../carreras_pendiente.mp3';
        let audio = new Audio(src);
        audio.play();
      }
    }

    if (data.data.tipo == 2501) {
      if (window.tipo_user == "ADM") {
        datos = data.data.data;
        $('#marquesina_superior2').show();
        marquesina_superior2.start();
        let src = '../pendientes_retirar.mp3';
        let audio = new Audio(src);
        audio.play();
      }
    }

    if (data.data.tipo == 2502) {
      if (window.tipo_user == "ADM") {
        id = data.data.cab_id;
        $("#id_retirar"+id).remove();
      }
    }

    if (data.data.tipo == 3000) {
      update_pizarra_propuestas(data.data.data)
    }


  },

  // enviar_notificacion: function(data) {
  //   return this.perform('enviar_notificacion',data);
  // }
});

//   enviar_notificacion: function(tipo_op,tipo,enjuego,propuestas) {
//     if (tipo_op == 2) {
//      actualizar_operacion_apuesta(tipo,enjuego,propuestas);
//    }
//   }
// });
