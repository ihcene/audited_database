class AddTriggerToTables < ActiveRecord::Migration[8.0]
  def up
    (ActiveRecord::Base.connection.tables - ["schema_migrations", "ar_internal_metadata"]).each do |table_name|
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE TRIGGER #{table_name}_audit
        AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
        FOR EACH ROW EXECUTE FUNCTION audit.log_current_action();
      SQL
    end
  end
end
