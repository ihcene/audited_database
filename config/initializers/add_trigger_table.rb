module TableWithTrigger
  def create_table(table_name, **options)
    super
    add_trigger(table_name)
  end

  def drop_table(table_name, **options)
    remove_trigger(table_name)
    super
  end

  private

  def add_trigger(table_name)
    execute <<-SQL
      CREATE TRIGGER #{table_name}_audit_trigger
      AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
      FOR EACH ROW EXECUTE FUNCTION audit.log_current_action();
    SQL
  end

  def remove_trigger(table_name)
    execute <<-SQL
      DROP TRIGGER IF EXISTS #{table_name}_audit_trigger ON #{table_name};
    SQL
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SchemaStatements.prepend(TableWithTrigger)
end