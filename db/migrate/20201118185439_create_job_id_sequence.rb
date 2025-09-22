class CreateJobIdSequence < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
        CREATE SEQUENCE reference_id START 1;
      SQL
  end

  def down
    execute <<-SQL
        DROP SEQUENCE reference_id;
      SQL
  end
end
