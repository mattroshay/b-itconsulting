class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show, :index]

  def new
    @article = Article.new
  end

  def index
    @articles = Article.order(created_at: :desc)
  end

  def show
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(
      :title, :date, :content,
      media: [] 
    )
  end
end
