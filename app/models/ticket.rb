class Ticket < ApplicationRecord
    belongs_to :usuarios_taquilla
    has_many :tickets_detalles
    scope :tickets_by_client, -> (client_id, date_start, date_end) { where(usuarios_taquilla_id: client_id).where(created_at: date_start.to_time.beginning_of_day..date_end.to_time.end_of_day).ids }

end
