module CustomTransactionBehavior
  def begin_db_transaction
    super
    internal_execute("SET LOCAL app.current_user_id to '#{Current.user&.id || 'Guest'}';", "TRANSACTION", allow_retry: true, materialize_transactions: false)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements.prepend(CustomTransactionBehavior)
end