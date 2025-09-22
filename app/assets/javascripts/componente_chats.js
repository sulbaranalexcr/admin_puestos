
Vue.component('contedor-chats', {
  data: function () {

  },
template: `
  <div>
    <table id="recargas_index" class="table table-bordered table-striped dataTable" role="grid">
      <thead>
        <tr>
          <th style="text-align: left;width: 20%;background-color: #D5DBDB"> Usuario </th>
          <th style="text-align: left;width: 10%;background-color: #D5DBDB"> Hora </th>
          <th style="text-align: left;width: 50%;background-color: #D5DBDB"> Mensaje </th>
          <th colspan="2" style="text-align: left;width: 20%;background-color: #D5DBDB"> Acciones </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(chat, index) in chats">
          <td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            {{ chat.message.data.user }} - {{ chat.message.data.internal_id ? chat.message.data.internal_id : '' }}
          </td>
          <td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            {{ chat.message.data.time }}
          </td>
          <td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            {{ chat.message.data.msg }}
          </td>
          <!--td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            <botton class="btn btn-danger" @click="remove_item(index)" v-show="index == 0">Eliminar</button>
          </td-->
          <td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            <botton class="btn btn-success" @click="send_item(index, 1)" v-show="index == 0">Lo pueden ver todos</button>
          </td>
          <td style="cursor: zoom-in;font-weight: bold;line-height:20pt;font-size: 14px;">
            <botton class="btn btn-warning" @click="send_item(index, 2)" v-show="index == 0">Solo lo vera el usuario</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
`,
  props: ['chats'],
 
  methods: {

   
    remove_item: function(index){
      axios({
        method: 'POST',
        url: '/unica/chats/remove_item',
        data: { id: data_chats.chats[index].id },
      })
      .then(function (response) {
        data_chats.chats.splice(index, 1);
      })
    },
    send_item: function (index, type) {
      axios({
        method: 'POST',
        url: '/unica/chats/send_item',
        data: { id: data_chats.chats[index].id, type: type },
      })
        .then(function (response) {
          data_chats.chats.splice(index, 1);
        })
    },
    send_data: function(){
      const inputOptions = new Promise((resolve) => {
        setTimeout(() => {
          }, 1000)
      })
      Swal.fire({ title: 'Espere, enviando datos...',
        input: 'radio',
        inputOptions: inputOptions,
        inputValidator: (value) => {
        }
    })
      axios({
          method: 'POST',
          url: '/unica/generador_propuestas/save_parameters',
          data: { data: this.data, sport_id: this.sport_id },
      })
      .then(function (response) {
          if (response.status == 200){
            Swal.close()
            Swal.fire('Completado', 'Datos almacenado.', 'success' )
          }else{
              Swal.close();
              Swal.fire(
                  'Error',
                  'Error del sistema',
                  'error'
              )

          }
      })
      .catch(function (error) {
          swal.close();
      });
    }

  }
})

