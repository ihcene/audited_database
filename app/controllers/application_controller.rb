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

