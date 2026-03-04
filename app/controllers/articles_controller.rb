class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :index]
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  def new
    @article = Article.new
  end

  def create
    @article = current_user.articles.build(article_params)

    if @article.save
      # Queue LinkedIn sharing if enabled
      LinkedinShareJob.perform_later(@article.id) if Rails.application.config.x.linkedin.enabled
      InstagramShareJob.perform_later(@article.id) if Rails.application.config.x.instagram.enabled
      redirect_to article_path(@article), notice: "Article créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: "Article mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def index
    @articles = Article.order(date: :desc, created_at: :desc)
  end

  def show
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: "Article supprimé avec succès."
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(
      :title, :date, :rich_content,
      media: []
    )
  end
end
