require 'rss'
require 'open-uri'
require 'textmood'
require 'nokogiri'

class ArticleSearchJob < ApplicationJob
  queue_as :default

  @@tm = TextMood.new(language: "da")
  @@guid_regex = /<guid.*?>(.*?)<\/guid>/
  @@use_simple_analysis = false
  Ruby::OpenAI.configure do |config|
    config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
    if @@use_simple_analysis && config.access_token == nil then @@use_simple_analysis = false end
  end
  @@openai_client = OpenAI::Client.new
  def perform(*args)
    p "Loading new articles"
    begin
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      fetch_wallnot
      ActiveRecord::Base.logger = old_logger
      p "Job done"
    rescue => error
      p "Failed job: " + error.message
    ensure
      ArticleSearchJob.set(wait: 5.minutes).perform_later
    end
  end

  def fetch_wallnot
    url = "https://wallnot.dk/rss"
    URI.open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        guid = item.guid.to_s.match(@@guid_regex)[1]

        if Article.exists?(guid: guid) then
          next
        end
        published_time = Time.parse(item.pubDate.to_s)
        published = published_time.to_s
        source = item.description[12, item.description.length]
        scrape = scrape_content(item.link, source)
        if scrape == nil then
          next
        end
        content, author, img = *scrape
        score = 0
        if @@use_simple_analysis
          score = @@tm.analyze(item.title + content)
        else
          text = item.title + content
          if text.length > 1800 then
            text = text[0, 1800]
          end
          prompt = 'Make a sentiment analysis on the following text":
                  Desired answers: ["Positive", "Negative"]
                  text: """
                  ' + text + '
                  """"
                  Sentiment:'
          response = @@openai_client.completions(
            parameters: {
              model: "text-babbage-001",
              prompt: prompt
            })
          error = response["error"]
          if error
            puts error["message"]
            puts "Using fallback"
            score = @@tm.analyze(item.title + content)
          else
            result = response["choices"][0]["text"].strip.downcase
            case result
            when "positiv"
              score = 1
            when "positive"
              score = 1
            when "negativ"
              score = -1
            when "negative"
              score = -1
            else
              score = 0
              puts "Unknown response from AI:" + result
              next
            end
          end
        end

        @article = Article.new
        @article.title = item.title
        @article.body = content
        @article.guid = guid
        @article.published = published
        @article.link = item.link
        @article.score = score
        @article.source = source
        @article.author = author
        @article.image_url = img
        @article.validated = false
        @article.save
      end
    end
  end

  def scrape_content(link, source)
    case source
    when "EB"
      puts "EB"
      scraped = scrape(link, '.art-subtitle', '.article-bodytext p', 'div[itemtype="http://schema.org/Person"] a', 'figure img')
      if scraped then
        content, author, img = *scraped
        if img.starts_with?("/") then
          img = "https://ekstrabladet.dk" + img
        end
        [content, author, img]
      else
        nil
      end
    when "BT"
      puts "BT"
      scraped = scrape(link, '.art-subtitle', '.article-bodytext p', 'div[itemtype="http://schema.org/Person"] a', 'figure img')
      if scraped then
        content, author, img = *scraped
        if content.starts_with?("Hov, giv os lov at afspille artiklen. Den er klar, når du har klikket 'Tillad alle'") then
          content = content[83, content.length]
        end
        [content, author, img]
      else
        nil
      end

    when "Altinget"
      puts "Altinget"
      scrape(link, '.standfirst p', '#page article article p', nil, 'figure img')
    when "DR"
      puts "DR"
      scrape(link, 'p.dre-article-title__summary', 'div[itemprop="articleBody"] p', nil, 'figure img')
    when "TV 2"
      puts "TV 2"
      scrape(link, '.tc_page__body__standfirst strong', 'article .tc_richcontent p', nil, 'figure img')
    when "Politiken"
      puts "Politiken"
      scrape(link, '.summary__p', '.article__body p.body__p', nil, 'figure img')
    when "Jyllands-Posten"
      puts "Jyllands-Posten"
      scrape(link, '.c-article-top-info__description', '.c-article-text-container p', '.c-article-top-byline__name', 'figure img')
    when "Berlingske"
      puts "Berlingske"
      scrape(link, '.article-header__intro', '.articleBody p', '.article-byline__author-name', 'figure img')
    else
      puts "Unsupported source: #{source}"
      nil
    end
  end

  def scrape(link, standfirst_query, paragraf_query, author_query, image_query)
    doc = nil
    begin
      doc = Nokogiri::HTML(URI.open(link))
    rescue => error
      puts error.message
      return
    end
    standfirst = standfirst_query ? doc.css(standfirst_query)[0] : nil
    content = standfirst ? standfirst.content : ""
    if paragraf_query
      doc.css(paragraf_query).each do |paragraf|
        content += (content == "" ? "" : " ") + paragraf.content
      end
    end
    author = ""
    if author_query
      author_element = doc.css(author_query)[0]
      author = author_element ? author_element.content : ""
    end
    img = ""
    if author_query
      img_element = doc.css(image_query)[0]
      img = img_element ? img_element["src"] : ""
    end
    [content, author, img]
  end
end
