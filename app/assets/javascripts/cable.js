// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
//= require action_cable
//= require_self
//= require_tree ./channels

(function() {
  // App.cable = ActionCable.createConsumer("https://admin.betsolutionsgroup.com/cable");
  // this.App2 || (this.App2 = {});
  // App2.cable = ActionCable.createConsumer("https://taquilla.betsolutionsgroup.com/cable");
  // this.App3 || (this.App3= {});
  // App3.cable = ActionCable.createConsumer("https://taquilla.betsolutionsgroup.com/cable");
  // App.cable = ActionCable.createConsumer();
  this.App || (this.App = {});
  App.cable = ActionCable.createConsumer();
  this.App2 || (this.App2 = {});
  App2.cable = ActionCable.createConsumer();
  this.App3 || (this.App3 = {});
  App3.cable = ActionCable.createConsumer();

}).call(this);
