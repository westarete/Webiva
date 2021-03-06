# Copyright (C) 2009 Pascal Rettig.


class JobsList::JobsListJobsList < DomainModel

  validates_presence_of :name
  validates_presence_of :content_filter

  belongs_to :content_model
  belongs_to :content_publication

  has_many :jobs_list_posts, :dependent => :destroy, :include => :active_revision
  has_many :jobs_list_categories, :class_name => 'JobsList::JobsListCategory', :dependent => :destroy, :order => 'jobs_list_categories.name'

  serialize :options_data

  cached_content # Add cached content support 

  attr_accessor :add_to_site

  include SiteAuthorizationEngine::Target
  access_control :edit_permission

  serialize :options
  
  content_node_type :jobs_list, "JobsList::JobsListPost", :content_name => :name,:title_field => :title, :url_field => :permalink

  def content_admin_url(jobs_list_entry_id)
    {  :controller => '/jobs_list/manage', :action => 'post', :path => [ self.id, jobs_list_entry_id ],
       :title => 'Edit Jobs List Entry'.t}
  end

  def content_categories
    self.jobs_list_categories
  end

  def content_category_nodes(category_id)
    ContentNode.all :conditions => {:node_type => 'JobsList::JobsListPost', :content_type_id => self.content_type.id, 'jobs_list_posts_categories.jobs_list_category_id' => category_id}, :joins => 'JOIN jobs_list_posts_categories ON jobs_list_post_id = node_id'
  end

  def paginate_posts_by_date(page,date_name,items_per_page,options = {})
    today = Time.now.at_midnight; end_time = Time.now
    case date_name.downcase
    when 'day':   start_time = today
    when 'week':  start_time = today - 7.days;
    when 'month': start_time = today.at_beginning_of_month
    when 'last_month': start_time = (today - 1.months).at_beginning_of_month; end_time = start_time.at_end_of_month
    when 'six_months': start_time = today - 6.months
    else return nil,[]
    end

    JobsList::JobsListPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :jobs_list_posts_categories ],
                            :order => 'published_at DESC',
                            :conditions => [ "jobs_list_posts.status = \"published\" AND jobs_list_posts.jobs_list_jobs_list_id=? and published_at BETWEEN ? and ?",self.id,start_time,end_time],
                            :per_page => items_per_page }.merge(options))
  end                       


  def paginate_posts_by_category(page,cat,items_per_page,options = {})
    cat = [ cat] unless cat.is_a?(Array)

    category_ids = self.jobs_list_categories.find(:all,:conditions => { :name => cat },:select=>'id').map(&:id)

    category_ids = [ 0] if category_ids.length == 0

    JobsList::JobsListPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :jobs_list_posts_categories ],
                            :order => 'published_at DESC',
                            :conditions => [ "jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ? AND jobs_list_posts.jobs_list_jobs_list_id=? AND jobs_list_posts_categories.jobs_list_category_id in (?)",Time.now,self.id, category_ids],
                            :per_page => items_per_page }.merge(options))
  end                       


  def paginate_posts_by_tag(page,tag,items_per_page,options = {})

    tag = [ tag ] unless tag.is_a?(Array)

    tag_ids = ContentTag.find(:all,:conditions => { :name => tag },:select => 'id').map(&:id)
    tag_ids = [ 0 ] if tag_ids.length == 0

    JobsList::JobsListPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :content_tag_tags ],
                            :order => 'published_at DESC',
                            :conditions => ["jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ? AND jobs_list_posts.jobs_list_jobs_list_id=? AND content_tag_tags.content_tag_id in (?)",Time.now,self.id,tag_ids],
                            :per_page => items_per_page}.merge(options))
  end

  def paginate_posts_by_month(page,month,items_per_page,options = {})
    begin
      if month =~ /^([a-zA-Z]+)([0-9]+)$/
        tm = Time.parse($1 + " 1 " + $2)
      else
        return paginate_posts_by_date(page,month,items_per_page,options)
      end
    rescue Exception => e
      return nil,[]
    end

    JobsList::JobsListPost.paginate(page, {
			    :include => [ :active_revision, :jobs_list_categories ],
			    :order => 'published_at DESC',
			    :conditions =>   ["jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ? AND jobs_list_posts.jobs_list_jobs_list_id=? AND jobs_list_posts.published_at BETWEEN ? AND ?",Time.now,self.id,tm.at_beginning_of_month,tm.at_end_of_month],
			    :per_page => items_per_page }.merge(options))

  end

  def paginate_posts_by_job_status(page,job_status,items_per_page,options={})
    JobsList::JobsListPost.paginate(page, {
          :include => [ :active_revision, :jobs_list_categories ],
          :order => 'published_at DESC',
          :conditions => ["jobs_list_posts.status = \"published\" AND
                           jobs_list_posts.published_at < ? AND
                           jobs_list_posts.jobs_list_jobs_list_id = ? AND
                           jobs_list_post_revisions.job_status = ?",
                           Time.now, self.id, job_status],
          :per_page => items_per_page }.merge(options))
  end

  def paginate_posts(page,items_per_page,options = {})
    opts = options.symbolize_keys

    post_options = {  :include => [ :active_revision ], 
                      :order => 'published_at DESC',
                      :conditions => ["jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ?  AND jobs_list_jobs_list_id=?",Time.now,self.id],
                      :per_page => items_per_page }

    if tag = opts.delete(:tag_filter)
      tag = [ tag ] unless tag.is_a?(Array)

      tag_ids = ContentTag.find(:all,:conditions => { :name => tag },:select => 'id').map(&:id)
      tag_ids = [ 0 ] if tag_ids.length == 0

      post_options[:include] << :content_tag_tags
      post_options[:conditions][0] += "  AND content_tag_tags.content_tag_id in (?)"
      post_options[:conditions] << tag_ids
    end

    if cat = opts.delete(:category_filter)
      cat = [ cat] unless cat.is_a?(Array)
      category_ids = self.jobs_list_categories.find(:all,:conditions => { :name => cat },:select=>'id').map(&:id)

      category_ids = [ 0] if category_ids.length == 0
     post_options[:include] << :jobs_list_posts_categories
      post_options[:conditions][0] += "  AND jobs_list_posts_categories.jobs_list_category_id in (?)"
      post_options[:conditions] << category_ids
    end

    JobsList::JobsListPost.paginate(page,post_options.merge(opts))

  end


  def find_post_by_permalink(permalink)
    JobsList::JobsListPost.find(:first,
                        :include => [ :active_revision ],
                        :order => 'published_at DESC',
                        :conditions => ["jobs_list_posts.status in('published') AND jobs_list_jobs_list_id=? AND jobs_list_posts.permalink=?",self.id,permalink])
  end

  def content_type_name
    "Jobs List"
  end

  def self.filter_options
    ContentFilter.filter_options
  end

  def before_save
    self.content_publication_id = nil if self.content_model.nil? || self.content_publication.nil? || self.content_model.id != self.content_publication.content_model_id
  end

  def content_detail_link_url(path,obj)
    if self.jobs_list_options.category_override
      "#{path}/#{obj.first_category.permalink}/#{obj.permalink}"
    else 
      "#{path}/#{obj.permalink}"
    end
  end

  def jobs_list_options(val=nil)
    @options_cache = nil if val
    @options_cache ||= JobsListOptions.new(val || self.options_data)
    @options_cache
  end

  def jobs_list_options=(val)
    self.options_data = jobs_list_options(val).to_hash
  end

  class JobsListOptions < HashModel
    attributes :category_override => false
    boolean_options :category_override
  end

end
