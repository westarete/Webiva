# Copyright (C) 2009 Pascal Rettig.


class JobsList::RssHandler

  def self.feed_rss_handler_info
    {
    :name => "Jobs List RSS Feed"
    }
  end

  def initialize(options)
    @options = options
    @feed_id = @options.feed_identifier
    @feed_site_node,@feed_jobs_list_id,@detail_page_id = @feed_id.split(",")
  end

  def set_path(path)
    @path = path
    if @path && @options.subfeed_options.present?
      @list_by = @options.subfeed_options
      @list_type = @path[0].to_s.downcase
    end

  end
  
  def get_feed
    @node = SiteNode.find_by_id(@feed_site_node)
    @jobs_list = JobsList::JobsListJobsList.find_by_id(@feed_jobs_list_id)
    @detail_page = SiteNode.find_by_id(@detail_page_id)
    
    limit = @options.limit > 0 ? @options.limit : 10
    
    if @node && @jobs_list
      data = { :title => @jobs_list.name,
               :description => @jobs_list.name,
               :link => Configuration.domain_link(@node.node_path),
               :items => []}

      if @list_by.to_s == 'category'
        pages,posts = @jobs_list.paginate_posts_by_category(1,@list_type,limit)
      elsif @list_by.to_s == 'tag'
        pages,posts = @jobs_list.paginate_posts_by_tag(1,@list_type,limit)
      else
        pages,posts = @jobs_list.paginate_posts(1,limit)
      end

      posts.each do |post|
        item = { :title => post.title,
                 :guid => post.id,
                 :published_at => post.published_at.to_s(:rfc822),
                 :description => Util::HtmlReplacer.replace_relative_urls(post.body_content)
                }
        item[:creator] = post.job_status unless post.job_status.blank?
        post.jobs_list_categories.each do |cat|
          item[:categories] ||= []
          item[:categories] << cat.name
        end
        if @detail_page
          item[:link] = Configuration.domain_link(@detail_page.node_path + "/" +  post.permalink)
          item[:guid] = item[:link]
        end
        
        if post.media_file
          item[:enclosure] = post.media_file
        end

        if post.domain_file
          item[:thumbnail] = post.domain_file
        end

        data[:items] << item
      end
      
      data
    else
      nil
    end
  end
  
  class Options < Feed::AdminController::RssModuleOptions
    attributes :feed_identifier => nil, :limit => 10, :full => false, :subfeed_options => nil

    validates_presence_of :feed_identifier, :limit
    validates_numericality_of :limit


    boolean_options :full
    integer_options :limit
    
    has_options :subfeed_options, [['None',nil],['Category','category'],['Tag','tag']]

    options_form(fld(:feed_identifier, :select, :options => :feed_identifier_options, :label => 'Feed'),
		 fld(:limit, :text_field),
     fld(:full,:yes_no),
     fld(:subfeed_options,:radio_buttons,:options => :subfeed_options_select_options,:description => 'Allows sub feeds by category or tag at a sub-url')
		 )

    def validate
      if self.feed_identifier
	errors.add(:feed_identifier) unless self.feed_identifier_options.rassoc(self.feed_identifier)
      end
    end


    def feed_identifier_options
      revisions = PageRevision.find(:all,:joins => :page_paragraphs,
				    :conditions => 'display_module = "/jobs_list/page" AND display_type = "entry_list" AND page_revisions.active=1 AND revision_type="real"')
      opts = [['--Select Feed--', nil]]
    
      revisions.each do |rev|
        par = rev.page_paragraphs.detect { |p| p.display_module =='/jobs_list/page' && p.display_type == 'entry_list' }
        jobs_list = JobsList::JobsListJobsList.find_by_id(par.data[:jobs_list_id]) if par
        detail_page = par.data[:detail_page] if par && par.data[:detail_page]

        if par && jobs_list && rev.revision_container.is_a?(SiteNode)
          opts << [ jobs_list.name + ' - ' + rev.revision_container.node_path, "#{rev.revision_container_id},#{jobs_list.id},#{detail_page}" ]
        end
      end
      opts
    end
  end

end
