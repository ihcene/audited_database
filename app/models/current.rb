class Current < ActiveSupport::CurrentAttributes
  attribute :user, :open_struct
end