class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :about, :contact, :competences ]

  def home
  end
  def about
  end
  def contact
  end
  def competences
  end
end
