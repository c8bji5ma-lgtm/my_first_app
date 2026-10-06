class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    render user_signed_in? ? :home : :top
  end

  def home
  end

  def my_page
  end
end
