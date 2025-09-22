App3.publicas_deportes = App3.cable.subscriptions.create("PublicasDeportesChannel", {
connected: function() {
    console.log('Conectado al canal taquilla Unica.');
    // try {
    //   swal.close();
    // }
    // catch(error) {
    // }
  },


  disconnected: function() {
    console.log('Desconectado del canal  taquilla Unica.');
    //taquilla_desconectada();
  },

  received: function(data) {
    try {
          if (data.data.tipo == 1){
            set_hora_taquillas(data.data.hora);
          }
          if (data.data.tipo == 10){
            redraw_act(data.data.id,data.data.cantidad);
          }
          if (data.data.tipo == 11){
            update_cant_taquillas(data.data.cantidad);
          }
          if (data.data.tipo == 12){
            update_cant_cruzadas(data.data.cantidad,data.data.moneda);
          }
          if (data.data.tipo == 500){
            if (Number(window.user_id) == Number(data.data.grupo)){
              revisar_solicitudes();
            }
          }
          if (data.data.tipo == 501){
            if (Number(window.user_id) == Number(data.data.grupo)){
              revisar_solicitudes();
            }
          }

      }
      catch(error) {
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
