require 'nokogiri'
require './base_image_getter.rb'

class ImageGetter < BaseImageGetter
  # 開始ページ
  START_PAGE_URL = 'https://XXXXXXX'

  def initialize
    super START_PAGE_URL
  end

  def main
    begin
      @start_url = START_PAGE_URL

      @sleep_second = 3

      execute
    rescue => e
      puts "[ERROR] #{e.message} #{e.backtrace}"
      exit 1
    end
  end

  def analytics_html(doc, index)
    next_url = nil
    doc.xpath('//a[@id="next"]').each do |node|
      # タイトルを表示
      # p node.css('h3').inner_text
      # p node.css('img').attribute('src').value
      # p node.css('a').attribute('href').value
      next_url = node.attribute('href').value
    end

    image_url = nil
    doc.xpath('//img[@id="img"]').each do |node|
      image_url = node.attribute('src').value
    end

    save_image image_url, "#{index}_"

    next_url
  end
end

ImageGetter.new.main