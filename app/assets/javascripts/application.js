// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require vue
//= require jquery
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require_tree ./libs/




document.addEventListener('turbolinks:load',function() {
  //loading config admiLTE
  window.loadConfigTheme();
  window.loadConfigThemeSkins();
    $.each($('.treeview'), function(index,element){
      var element = $(element);
      if (element.find('li.active').length > 0){
        element.addClass('active');
      }
    });

});

function swalert_espera(mensaje){
  const inputOptions = new Promise(resolve => {
    setTimeout(() => {}, 1000)
  })

  Swal.fire({
      title: mensaje,
      input: 'radio',
      inputOptions: inputOptions,
      inputValidator: (value) => {
      }
  })
}
