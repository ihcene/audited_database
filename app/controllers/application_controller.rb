require "ostruct"

class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  around_action :set_user

  private

  def set_user
    Current.set(user: OpenStruct.new(id: 123)) do
      yield
    end
  end
end

module CustomTransactionBehavior
  def begin_db_transaction
    super
    internal_execute("SET LOCAL app.current_user_id to '#{Current.user&.id || 'Guest'}';", "TRANSACTION", allow_retry: true, materialize_transactions: false)
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements.prepend(CustomTransactionBehavior)

