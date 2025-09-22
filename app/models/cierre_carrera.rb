class CierreCarrera < ApplicationRecord
   belongs_to :carrera
   belongs_to :user, optional: true
   # has_one :user, foreign_key: "id", primary_key: 'id'
end
