class ArticlesController < ApplicationController
  http_basic_authenticate_with name: "d", password: "d", except: [:index, :show]

  def index
    @articles = Article.all
    @sources = @articles.group(:source).select("source as name, count(*) as total_count, count(case when score >= 1 then 1 end) as score_greater_than_one")

  end
  def show
    @article = Article.find(params[:id])
  end
  def new
    @article = Article.new
  end
  
  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to @article
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    redirect_to root_path, status: :see_other
  end
  
  private def article_params
      params.require(:article).permit(:title, :body)
  end
end
