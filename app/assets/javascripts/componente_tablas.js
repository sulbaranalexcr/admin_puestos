
Vue.component('contenedor-tablas', {
  data: function () {
    return {
        restante: this.monto_tabla,
        total_tablas_todas: 0
    }
  },
template: `
  <div>
    <div id="user_wrapper" class="dataTables_wrapper form-inline dt-bootstrap" v-if="show_horses">
    <div class="row">
        <div class="col-sm-8 text-right">
          <span style="background-color: chartreuse; padding: 5px; margin-right: 10px; display: inline-block;">Monto a Pagar: {{ monto_tabla }} </span><br><br>
            <table id="caballos_enter" class="table table-bordered table-striped dataTable" role="grid">
                <thead>
                <tr>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px">Numero</th>
                    <th class="col-xs-2 col-sm-2 text-left" style="width: 150px">Nombre</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px">Venta</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px">Riego</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px">Div.</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px">Disp.</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px; color:white; border-radius:6px; background-color: blue;">Valor</th>
                    <th class="col-xs-1 col-sm-1 text-center" style="width: 50px; color:white; border-radius:6px; background-color: blue;">C/Tablas</th>
                </tr>
                </thead>

                <tbody>
                    <tr v-for="horse in data">
                    <td class="col-sm-1 text-center"> {{ horse.numero_puesto }} </td>
                    <td class="col-sm-2 text-left" style="width: 80px;" > {{ horse.nombre }} {{ horse.retirado ? '(RET)' : '' }}</td>
                    <td class="col-sm-1">{{ horse.ventas }} </td>
                    <td class="col-sm-1">{{ horse.riesgo }} </td>
                    <td class="col-sm-1">{{ horse.div }} </td>
                    <td class="col-sm-1">{{ horse.disp }} </td>
                    <td class="col-sm-1"><input type="number" v-model="horse.valor" :disabled="horse.retirado" style="width: 100%;" @change="handleInputChange(1)"> </td>
                    <td class="col-sm-1"><input type="number" v-model="horse.ctablas" :disabled="horse.retirado" style="width: 100%;" @change="handleInputChange(2)"> </td>
                    </tr>
                </tbody>
                <tfoot>
                  <tr>
                    <th colspan="6" class="text-right">Restante:</th>
                    <th class="text-right">{{restante}}</th>
                    <th class="text-right">{{total_tablas_todas}}</th>
                  </tr>
                </tfoot>    
            </table>
            <p><label class="danger" v-show="Number(this.restante) < 0">Valor ingresado super el monto de la tabla</label></p>
        </div>
      </div>
      <div class="box-footer">
        <input type="button" value="Crear" class="btn btn-success" @click="crear()" v-show="Number(this.restante) == 0"/>
        <input type="button" value="Desactivar" class="btn btn-danger" @click="crear()" v-show="data_parameters.add && data_parameters.table_status == 'activa'"/>
        <input type="button" value="Activar" class="btn btn-success" @click="crear()" v-show="data_parameters.add && data_parameters.table_status == 'inactiva'"/>
      </div>
    </div>
  </div>
`,
  props: ['data', 'show_horses', 'monto_tabla'],
  methods: {
    crear: function () {
      params = { carrera_id: $('#carreras').val(), monto_tabla: this.monto_tabla, caballos: this.data }
      axios.post('/tablas/procesar_carga', params)
        .then(response => {
          console.log(response);
          swal("Completo", "Tabla de posiciones creada.", "success").then((aceptar) => {
            location.reload();
          });
        })
        .catch(error => {
          console.log(error);
          swal("Lo siento", "Ocurrio un error", "error");
        })

    },
    handleInputChange: function (event) {
      if (event == 1) {
        const total = this.data.reduce((accumulator, currentValue) => accumulator + Number(currentValue.valor), 0);
        this.restante = this.monto_tabla - total
      }else{
        this.total_tablas_todas = this.data.reduce((accumulator, currentValue) => accumulator + Number(currentValue.ctablas), 0);
      }
    }

  },
   
}
)

