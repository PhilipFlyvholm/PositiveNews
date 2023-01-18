class Admin::ValidateController < ApplicationController
  def index
    #get all articles that are not validated or null
    @articles = Article.where("validated is null or validated = false")

    #@articles = Article.all.where(validated: false)
  end

  skip_before_action :verify_authenticity_token
  def validate
    @article = Article.find(params[:id])
    score = params[:score] == "positive" ? 1 : 0
    @article.score = score
    @article.validated = "true"
    @article.save
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy
  end
end