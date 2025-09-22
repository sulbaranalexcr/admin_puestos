
// Vue.component('contedor-parametros', {
//   data: function () {

//   },
// template: `
//   <div>
//     <div v-for="(dat, name) in data">
//       <label >{{humanize(name)}}</label>
//       <div>
//         <table border="0" style="width: 95%">
//           <thead>
//             <tr>
//               <th>Desde</th>
//               <th>Hasta</th>
//               <th>Banquear</th>
//               <th>Jugar</th>
//             </tr>
//           </thead>
//           <tbody>
//             <tr v-for="(item, index) in dat">
//               <td style="width: 5%">
//                 <p> <input type="number" id="desde" class="form-control" v-model="item.header[0]"> </p>
//               </td>
//               <td style="width: 5%">
//                 <p> <input type="number" id="hasta" class="form-control" v-model="item.header[1]"> </p>
//               </td>
//               <td style="width: 5%">
//                 <p> <input type="number" id="desde" class="form-control" v-model="item.data.banquear"> </p>
//               </td>
//               <td style="width: 5%">
//                 <p> <input type="number" id="hasta" class="form-control" v-model="item.data.jugar"> </p>
//               </td>
//               <td style="width: 1%" valign="top" >
//                 <input type="button" class="btn btn-danger" value="X" v-on:click="remove_item(name, index)" v-if="index > 0">
//               </td>
//               </tr>
//             </tbody>
//           </table>
//           <input type="button" class="btn btn-success" value="+" v-on:click="new_item(name)" style="float: right"><br>
//           <hr style="border: solid 1px">
//       </div>
//     </div>
//     <input type="button" class="btn btn-success" value="Aceptar" v-on:click="send_data()"><br>

//   </div>
// `,
//   props: ['data', 'sport_id'],
//   methods: {
//     new_item: function(name){
//       this.data[name].push({ header: [0, 0], data: { banquear: 0, jugar: 0}})
//     },
//     remove_item: function(name, index){
//       this.data[name].splice(index, 1)
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
//           url: '/unica/generador_propuestas/save_parameters',
//           data: { data: this.data, sport_id: this.sport_id },
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
//     humanize: function(str) {
//           return str
//               .replace(/^[\s_]+|[\s_]+$/g, '')
//               .replace(/[_\s]+/g, ' ')
//               .replace(/^[a-z]/, function(m) { return m.toUpperCase(); });
//         }

//     }
// })

