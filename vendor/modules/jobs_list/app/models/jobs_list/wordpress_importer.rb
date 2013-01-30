require 'nokogiri'

class JobsList::WordpressImporter
  attr_accessor :xml, :jobs_list, :images, :folder, :error, :import_comments, :import_pages

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def initialize
    self.images = {}
    self.import_pages = true
    self.import_comments = true
  end

  def folder
    @folder ||= DomainFile.push_folder self.jobs_list.name
  end

  def import_file(file)
    file = file.filename if file.is_a?(DomainFile)
    File.open(file, 'r') { |f| self.xml = f.read }
    true
  end

  def import_site(url, username, password)
    service = JobsList::WordpressWebService.new url, username, password
    unless service.login
      self.error = service.error
      return false
    end

    self.xml = service.export
    unless self.xml
      self.error = service.error
      return false
    end

    true
  end

  def escape_xml!(xml)
    xml.gsub!('excerpt:encoded>', 'excerpt>')
    xml.gsub!(/<category domain="tag"(.*?)<\/category>/, '<tag\1</tag>')
    xml.gsub!(/<\/?atom:.*?>/, '')
    xml.gsub!("& ","&amp; ")
    xml.gsub!(/<wp:postmeta>.*?<\/wp:postmeta>/m, '')
    xml.gsub!(/\/\/\s*<!\[CDATA\[(.*?)\/\/\s*\]\]/m, '\1')
  end

  def rss_header
    @rss_header ||= '<?xml version="1.0" encoding="UTF-8"?>' + self.xml.match(/(<rss.*?>)/m).to_s
  end

  def rss_footer
    '</rss>'
  end

  def jobs_list_posts
    self.xml.scan /<item>.*?<\/item>/m do |item|
      item = item.to_s
      escape_xml! item
      item = Hash.from_xml "#{self.rss_header}#{item}#{self.rss_footer}"
      item = item['rss'] && item['rss']['item'] ? item['rss']['item'] : nil
      yield item if item
    end
  end

  def jobs_list_categories
    self.xml.scan /<wp:category>.*?<\/wp:category>/m do |category|
      category = category.to_s
      escape_xml! category
      category = Hash.from_xml "#{self.rss_header}#{category}#{self.rss_footer}"
      category = category['rss'] && category['rss']['category'] ? category['rss']['category'] : nil
      yield category if category
    end
  end

  def import
    unless self.xml.include?('<channel>')
      self.error = 'WordPress file is invalid'
      return false
    end

    categories = {}
    self.jobs_list_categories do |category|
      cat = self.push_category(category)
      next unless cat
      categories[category['cat_name']] = cat
    end

    self.jobs_list_posts do |item|
      if item['post_type'] == 'post'
        self.create_post categories, item
      elsif item['post_type'] == 'page'
        self.create_page item
      end
    end

    true
  end

  def push_category(opts={})
    name = opts['cat_name']
    return nil if name == 'Uncategorized'
    return nil if name.blank?
    self.jobs_list.jobs_list_categories.find_by_name(name) || self.jobs_list.jobs_list_categories.create(:name => name)
  end

  def parse_body(body)
    body.gsub!(/(\[caption.*?\])(.*?)\[\/caption\]/) do |match|
      content = $2
      div = $1.sub('[caption', '<div').sub(/\]$/, '>').sub('align="', 'class="wp-caption ')

      caption = ''
      if div =~ /caption=(["'])([^\1]+)\1/
        caption = $2
      end

      "#{div}#{content}<p class=\"wp-caption-text\">#{caption}</p></div>"
    end

    body.gsub!(/src=("|')([^\1]+?)\1/) do |match|
      quote = $1
      src = $2
      file = nil
      file = self.folder.add(src) if src =~ /^http/ && src.length < 200
      if file
        self.images[src] = file
        "src=#{quote}#{file.editor_url}#{quote}"
      else
        match
      end
    end

    self.images.each do |src, file|
      body.gsub! src, file.editor_url
    end

    body.strip!
    body = simple_format(body) unless body.blank?
    body
  end

  def create_post(categories, item={})
    body = item['encoded']
    return if body.blank?
    return if self.jobs_list.jobs_list_posts.find_by_permalink item['post_name']

    status = item['status'] == 'publish' ? 'published' : 'draft'
    published_at = Time.now
    begin
      published_at = Time.parse(item['pubDate'])
    rescue
    end

    posted_at = Time.now
    begin
      posted_at = Time.parse(item['post_date'])
    rescue
    end

    post = self.jobs_list.jobs_list_posts.create :body => self.parse_body(body), :job_status => item['creator'], :title => item['title'], :published_at => published_at, :status => status, :permalink => item['post_name'], :created_at => posted_at

    return unless post.id

    post_categories = item['category']
    post_categories = [post_categories] unless post_categories.is_a?(Array)
    post_categories.uniq.each do |cat|
      next unless categories[cat]
      JobsList::JobsListPostsCategory.create :jobs_list_post_id => post.id, :jobs_list_category_id => categories[cat].id
    end

    comments = item['comment']
    if comments
      comments = [comments] unless comments.is_a?(Array)
      comments.each do |comment|
        self.create_comment post, comment
      end
    end

    if item['tag']
      tags = item['tag']
      tags = [tags] unless tags.is_a?(Array)
      post.add_tags tags.join(',')
    end

    post
  end

  def create_comment(post, comment)
    return unless self.import_comments
    return if comment['comment_content'].blank?
    user = comment['comment_job_status_email'].blank? ? nil : EndUser.push_target(comment['comment_job_status_email'], :name => comment['comment_job_status'])
    rating = comment['comment_approved'] == "1" ? 1 : 0

    posted_at = Time.now
    begin
      posted_at = Time.parse(comment['comment_date'])
    rescue
    end

    Comment.create :target => post, :end_user_id => user ? user.id : nil, :posted_at => posted_at, :posted_ip => comment['comment_job_status_IP'], :name => comment['comment_job_status'], :email => comment['comment_job_status_email'], :comment => comment['comment_content'], :rating => rating, :website => comment['comment_job_status_url']
  end

  def create_page(item)
    return unless self.import_pages
    body = item['encoded']
    return if body.blank?

    path = nil
    begin
      uri = URI.parse(item['link'])
      path = uri.path.sub(/^\//, '').sub(/\/$/, '')
      path = SiteNode.generate_node_path(item['title']) if path.blank? && uri.query.include?('page_id')
    rescue
    end

    return unless path

    node_path = ''
    parent = SiteVersion.current.root_node
    path.split('/').each do |node_path|
      node_path = '' if node_path == 'home'
      parent = parent.push_subpage(node_path)
    end

    parent.push_subpage(node_path) do |nd, rv|
      rv.title = item['title']
      # Basic Paragraph
      rv.push_paragraph(nil, 'html') do |para|
        para.display_body = self.parse_body(body)
      end

      comments = item['comment']
      if comments
        comments = [comments] unless comments.is_a?(Array)
        comments.each do |comment|
          self.create_comment nd, comment
        end
      end
    end
  end
end
