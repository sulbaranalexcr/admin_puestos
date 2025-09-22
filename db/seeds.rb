# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


User.find_by_sql('TRUNCATE  table users RESTART IDENTITY')
User.create(username: 'admin', password: '123456', tipo: 'ADM', grupo_id: 0, activo: true)


TipoApuesta.find_by_sql('TRUNCATE  table tipo_apuesta RESTART IDENTITY')
TipoApuesta.create(nombre: '1 P', forma_pagar: 1)
TipoApuesta.create(nombre: '1 y 2 N', forma_pagar: 1)
TipoApuesta.create(nombre: '2 N', forma_pagar: 1)
TipoApuesta.create(nombre: '2 y 2 N', forma_pagar: 1)
TipoApuesta.create(nombre: '2 P', forma_pagar: 1)
TipoApuesta.create(nombre: '2 y 3 N', forma_pagar: 1)
TipoApuesta.create(nombre: '3 N', forma_pagar: 1)
TipoApuesta.create(nombre: '3 y 3 N', forma_pagar: 1)
TipoApuesta.create(nombre: '3 P', forma_pagar: 1)
TipoApuesta.create(nombre: '3 y 4 N', forma_pagar: 1)
TipoApuesta.create(nombre: '4 N', forma_pagar: 1)
TipoApuesta.create(nombre: '4 y 4 N', forma_pagar: 1)
TipoApuesta.create(nombre: '4 P', forma_pagar: 1)
TipoApuesta.create(nombre: '4 y 5 N', forma_pagar: 1)
TipoApuesta.create(nombre: '5 N', forma_pagar: 1)
TipoApuesta.create(nombre: '5 y 5 N', forma_pagar: 1)
TipoApuesta.create(nombre: '5 P', forma_pagar: 1)
TipoApuesta.create(nombre: 'P a P', forma_pagar: 1)
TipoApuesta.create(nombre: '10 a 9', forma_pagar: 0.9)
TipoApuesta.create(nombre: '10 a 8', forma_pagar: 0.8)
TipoApuesta.create(nombre: '10 a 7', forma_pagar: 0.7)
TipoApuesta.create(nombre: '10 a 6', forma_pagar: 0.6)
TipoApuesta.create(nombre: '10 a 5', forma_pagar: 0.5)
TipoApuesta.create(nombre: '10 a 4', forma_pagar: 0.4)
TipoApuesta.create(nombre: '10 a 3', forma_pagar: 0.3)
TipoApuesta.create(nombre: '10 a 2', forma_pagar: 0.2)

ActiveRecord::Base.connection.execute('CREATE SEQUENCE reference_id START 1;')

##### OJO  Para restaurar la base de datos desde el schema rake db:drop db:create db:schema:load