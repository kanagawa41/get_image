require 'net/http'
require 'uri'
require 'open-uri'
require 'openssl'
require 'nokogiri'

class BaseImageGetter

  FIND_URL_SAVE_PATH = './tmp/open_url.txt'

  attr_writer :start_url, :save_dir, :sleep_second, :loop_limit

  def initialize(start_url, save_dir=nil)
    raise "Don't set start page's url" unless start_url

    @start_url = start_url 
    @save_dir = save_dir ?  save_dir : './tmp/images/'
    @sleep_second = 5
    @loop_limit = -1

    open(FIND_URL_SAVE_PATH, 'w') unless File.exist?(FIND_URL_SAVE_PATH)
  end

  def execute
    next_url = @start_url

    loop.with_index do |_, i|
      html_doc = get_html(next_url)
      next_url = analytics_html(html_doc, i)

      raise "Can't find next page's url: #{next_url}" unless next_url

      raise "already find next url: #{next_url}" if exist_same_url? next_url

      # 検索したURLを記録
      open(FIND_URL_SAVE_PATH, 'a') do |f|
        f.puts next_url
      end

      break if @loop_limit > 0 && @loop_limit < i
      sleep @sleep_second
    end
  end

  # 次に遷移するURLを戻せば、処理を続ける
  def analytics_html(doc, index)
    raise "Called abstract method: #{__method__}"
  end

  protected
    def save_image(url, prefix=nil)
      filename = prefix ? "#{prefix}#{File.basename(url)}" : File.basename(url)
      file_path = "#{@save_dir}#{filename}"

      # write image adata
      open(file_path, 'wb') do |output|
        open(url) do |io|
          output.write(io.read)
        end
      end

      raise "Don't make image file." unless File.exist?(file_path)

      filename
    end

  private
    # 指定URLからHTMLを取得
    def get_html(url)
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http|
        http.request(req)
      }

      # htmlをパース(解析)してオブジェクトを生成
      doc = Nokogiri::HTML.parse(response.body, nil)
    end

    # 今まで検索したURLとマッチしないか？
    def exist_same_url?(url)
      File.open(FIND_URL_SAVE_PATH, "r:utf-8" ) do |f|
        while line = f.gets
          return true if url == line.strip
        end
      end

      false
    end

end