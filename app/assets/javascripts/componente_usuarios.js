// var users_parameters = new Vue({
//   el: '#data_vue_usuarios',
//   data: {
//     users: [],
//     deleted: []
//   },
//   mounted: function(){
//     axios({
//       method: 'POST',
//       url: '/unica/generador_propuestas/usuarios',
//       data: { },
//     })
//     .then(function (response) {
//         if (response.status == 200){
//           Swal.close()
//           users_parameters.users = response.data
//           console.log('aa',this.users)
//         }else{
//             Swal.close();
//             Swal.fire(
//                 'Error',
//                 'Error del sistema',
//                 'error'
//             )

//         }
//     })
//     .catch(function (error) {
//         swal.close();
//     });
//   },
//   methods: {
//     new_item: function(){
//       this.users.push({ id: null, correo: '', clave: '', porcentaje: 0 })
//     },
//     remove_item: function(index){
//       this.deleted.push({ id: this.users[index].id})
//       this.users.splice(index, 1)
//     },
//     send_data: function(){
//       const inputOptions = new Promise((resolve) => {
//         setTimeout(() => {
//           }, 1000)
//       })
//       Swal.fire({ title: 'Espere, enviando datos...',
//         input: 'radio',
//         inputOptions: inputOptions,
//         inputValidator: (value) => {
//         }
//     })
//       axios({
//           method: 'POST',
//           url: '/unica/generador_propuestas/save_users',
//           data: { data: this.users, deleted: this.deleted },
//       })
//       .then(function (response) {
//           if (response.status == 200){
//             Swal.close()
//             Swal.fire('Completado', 'Datos almacenado.', 'success' )
//           }else{
//               Swal.close();
//               Swal.fire(
//                   'Error',
//                   'Error del sistema',
//                   'error'
//               )

//           }
//       })
//       .catch(function (error) {
//           swal.close();
//       });
//     },
//  },
//  template: `
//   <div>
//     <div>
//     <table border="0" style="width: 95%">
//         <thead>
//           <tr>
//             <th>Usuario</th>
//             <th>Clave</th>
//             <th >Porcentaje</th>
//             <th style="text-align: center">Genera</th>
//           </tr>
//         </thead>
//         <tbody>
//           <tr v-for="(item, index) in users">
//             <td>
//               <p> <input type="email" id="usuario" class="form-control" v-model="item.correo"> </p>
//             </td>
//             <td>
//               <p> <input type="text" id="clave" class="form-control" v-model="item.clave"> </p>
//             </td>
//             <td>
//               <p> <input type="number" id="porcentaje" class="form-control" v-model="item.porcentaje"> </p>
//             </td>
//             <td style="text-align: center !important" valign="middle" >
//               <input type="checkbox" v-model="item.can_send">
//             </td>
//             <td valign="top" >
//               <input type="button" class="btn btn-danger" value="X" v-on:click="remove_item(index)" v-if="index > 0">
//             </td>
//           </tr>
//         </tbody>
//       </table>
//         <input type="button" class="btn btn-success" value="+" v-on:click="new_item()" style="float: right"><br>
//         <hr style="border: solid 1px">
//     </div>
//     <input type="button" class="btn btn-success" value="Aceptar" v-on:click="send_data()"><br>

//   </div>
// `
// });

