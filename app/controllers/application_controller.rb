class ApplicationController < ActionController::Base
  # protect_from_forgery
  protect_from_forgery with: :exception
  include ApplicationHelper
  before_action :current_user
  before_action :read_color

  def read_color
    @color_admin = ENV['color_admin'] || '#3C8DBC'
  end

  def default_data_integrator
    { 'obtener_saldo' =>
  { 'metodo' => 'POST',
    'url' => 'http://localhost:3000/api/wallet/balance',
    'parametros_header' => [{ 'token' => 'api_key' }],
    'parametros_body' => [{ 'user_id' => 'user_id', 'user_token' => 'token' }],
    'retorno' =>
    { 'saldo' => "['balance']", 'moneda' => 'USD', 'estado' => "['status']" } },
      'debitar_saldo' =>
  { 'metodo' => 'POST',
    'url' => 'http://localhost:3000/api/wallet/debit',
    'parametros_header' => [{ 'token' => 'api_key' }],
    'parametros_body' =>
    [{ 'user_id' => 'user_id',
       'user_token' => 'token',
       'amount' => 'monto',
       'data' => 'detalle',
       'transaction_id' => 'transaction_id' }],
    'retorno' =>
    { 'saldo' => "['balance']", 'moneda' => 'USD', 'estado' => "['status']" } },
      'acreditar_saldo' =>
  { 'metodo' => 'POST',
    'url' => 'http://localhost:3000/api/wallet/credit',
    'parametros_header' => [{ 'token' => 'api_key' }],
    'parametros_body' =>
    [{ 'user_id' => 'user_id',
       'user_token' => 'token',
       'amount' => 'monto',
       'data' => 'detalle',
       'transaction_id' => 'transaction_id',
       'reference_id' => 'reference_id' }],
    'retorno' =>
    { 'saldo' => "['balance']", 'moneda' => 'USD', 'estado' => "['status']" } },
      'acreditar_saldo_bloque' =>
  { 'metodo' => 'POST',
    'url' => 'http://localhost:3000/api/wallet/credits',
    'parametros_header' => [{ 'token' => 'api_key' }],
    'parametros_body' =>
    [{ 'type' => 'credit', 'description' => 'detalle', 'users' => 'mensaje' }],
    'retorno' => { 'codigo' => "['status']" } } }
  end
end
