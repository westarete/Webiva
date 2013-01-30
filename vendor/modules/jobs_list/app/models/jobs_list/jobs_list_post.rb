# Copyright (C) 2009 Pascal Rettig.


class JobsList::JobsListPost < DomainModel

  validates_uniqueness_of :permalink, :scope => 'jobs_list_jobs_list_id'

  has_many :jobs_list_post_revisions, :class_name => 'JobsList::JobsListPostRevision', :dependent => :destroy

  belongs_to :active_revision, :class_name => 'JobsList::JobsListPostRevision', :foreign_key => 'jobs_list_post_revision_id'
  belongs_to :jobs_list_jobs_list
  
  has_many :jobs_list_posts_categories
  has_many :jobs_list_categories, :through => :jobs_list_posts_categories
  
  validates_presence_of :title

  validates_length_of :permalink, :allow_nil => true, :maximum => 128 

  validates_datetime :published_at, :allow_nil => true
   
  has_options :status, [ [ 'Draft','draft'], ['Published','published']]

  has_many :comments, :as => :target

  include Feedback::PingbackSupport

  cached_content :update => :jobs_list_jobs_list, :identifier => :permalink
  # Add cached content support, but make sure we update the jobs list cache element
  
  has_content_tags

  def first_category
    self.jobs_list_categories[0] || JobsList::JobsListCategory.new
  end

  def data_model
    return @data_model if @data_model
    return nil unless self.jobs_list_jobs_list && self.jobs_list_jobs_list.content_model
    @data_model = self.jobs_list_jobs_list.content_model.content_model.find_by_id self.data_model_id if self.data_model_id
    @data_model = self.jobs_list_jobs_list.content_model.content_model.new unless @data_model
    @data_model
  end

  def data_model=(opts)
    self.data_model.attributes = opts
  end

  def validate
    if self.status == 'published'  && !self.published_at.is_a?(Time)
      self.errors.add(:published_at,'is invalid')
    end

    self.errors.add_to_base('%s is invalid' / self.jobs_list_jobs_list.content_model.name) if self.data_model && ! self.data_model.valid?
  end
  
  content_node :container_type => :content_node_container_type,  :container_field => Proc.new { |post| post.content_node_container_id },
  :push_value => true, :published_at => :published_at, :published => Proc.new { |post| post.published? }



  def revision
    @revision ||= self.active_revision ? self.active_revision.clone : JobsList::JobsListPostRevision.new
  end

  # Special permalink for targeted jobs lists
  def target_permalink
    if self.jobs_list_jobs_list.targeted_jobs_list
      "#{self.jobs_list_jobs_list.targeted_jobs_list.url}/#{self.permalink}"
    else
      self.permalink
    end
  end

  def content_node_body(language)
    body = []
    body << self.active_revision.body_html if self.active_revision
    body << self.active_revision.job_status
    body += self.jobs_list_categories.map(&:name)
    body += self.content_tags.map(&:name)
    body.join(" ")
  end

  def content_node_container_type
    self.jobs_list_jobs_list && self.jobs_list_jobs_list.is_user_jobs_list? ? "JobsList::JobsListTarget" : 'JobsList::JobsListJobsList'
  end

  def content_node_container_id
    self.jobs_list_jobs_list.is_user_jobs_list? ? 'jobs_list_target_id' : 'jobs_list_jobs_list_id'
  end

  def jobs_list_target_id
    self.jobs_list_jobs_list.jobs_list_target_id
  end

  def comments_count
    return @comments_count if @comments_count
    @comments_count = self.comments.size
    return @comments_count 
  end

  def approved_comments_count
    @approved_comments_count ||= self.comments.with_rating(1).count
  end

  def self.paginate_published(page,items_per_page,jobs_list_ids = [],options = {})
    if jobs_list_ids.length > 0
      JobsList::JobsListPost.paginate(page, {
                              :include => [ :active_revision, :jobs_list_categories ],
                              :order => 'published_at DESC',
                              :conditions => ["jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ? AND jobs_list_posts.jobs_list_jobs_list_id IN (?)",Time.now,jobs_list_ids],
                              :per_page => items_per_page }.merge(options))
    else
      JobsList::JobsListPost.paginate(page, {
                              :include => [ :active_revision, :jobs_list_categories ],
                              :order => 'published_at DESC',
                              :conditions => ["jobs_list_posts.status = \"published\" AND jobs_list_posts.published_at < ?",Time.now],
                              :per_page => items_per_page }.merge(options))
    end
    
  end

  def generate_permalink!
      if permalink.blank? && self.active_revision
        date = self.published_at || Time.now
        permalink_try_partial = date.strftime("%Y-%m-") + self.active_revision.title.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
        permalink_try_partial = permalink_try_partial[0..59].gsub(/\-$/,"")
        idx = 2
        permalink_try = permalink_try_partial
        
        while(JobsList::JobsListPost.find_by_permalink(permalink_try,:conditions => ['id != ?',self.id || 0] ))
          permalink_try = permalink_try_partial + '-' + idx.to_s
          idx += 1
        end
        
        self.permalink = permalink_try
      elsif 
        self.permalink = self.permalink.to_s.gsub(/[^a-z+0-9\-]/,"")[0..127]
      end
  end

  def category_ids
    self.jobs_list_categories.collect(&:id)
  end

  def set_categories!(category_ids)
    categories_to_delete = []
    categories_to_add = []
    categories_to_keep = []
    category_ids ||= []

    # Find which categories to keep and delete
    # from the existing list
    self.jobs_list_categories.each do |cat|
      if(category_ids.include?(cat.id))
        categories_to_keep << cat.id
      else
        categories_to_delete << cat.id
      end
    end
    
    # Find the categories we need to add from our keep cacluation
    category_ids.each do |cat_id|
      categories_to_add << cat_id unless categories_to_keep.include?(cat_id)
    end

    self.jobs_list_posts_categories.each { |pc| pc.destroy }
    categories_to_add.each do |cat_id|
       self.jobs_list_posts_categories.create(:jobs_list_category_id => cat_id)
    end

    self.jobs_list_categories.reload

  end


  [ :title, :body, :job_status ].each do |fld|
    class_eval("def #{fld}; self.revision.#{fld}; end")
    class_eval("def #{fld}=(val); self.revision.#{fld} = val; end")
  end

  def name
     self.revision.title
  end

  [ :body_content ].each do |fld|
    class_eval("def #{fld}; self.revision.#{fld}; end")
  end

  def self.get_content_description 
    "Jobs List Post".t
  end

  def self.get_content_options
    self.find(:all,:order => 'title',:include => 'revision').collect do |item|
      [ item.revision.title,item.id ]
    end
  end

  include ActionView::Helpers::TextHelper

  def self.comment_posted(jobs_list_id)
     
    DataCache.expire_content("Jobs List")
    DataCache.expire_content("Jobs List Post")
  end


  def before_save
    if self.data_model
      self.data_model.save
      self.data_model_id = self.data_model.id
    end

    if @revision
      self.active_revision.update_attribute(:status,'old') if self.active_revision
      @revision = @revision.clone

      @revision.status = 'active'
      @revision.jobs_list_jobs_list = self.jobs_list_jobs_list
      @revision.jobs_list_post_id = self.id if self.id
      @revision.save

      self.jobs_list_post_revision_id = @revision.id
      self.generate_permalink!
    end
  end
  def after_create
    @revision.update_attribute(:jobs_list_post_id,self.id)
    @revision= nil
  end

  def after_update
    @revision = nil
  end

  def publish_now
    # then unless it's already published, set it to published and update the published_at time
    unless(self.status == 'published' && self.published_at && self.published_at < Time.now) 
        self.status = 'published'
        self.published_at = Time.now
    end
  end
  
  def publish!
    if self.publish_now
      self.save
    end
  end

  def unpublish!
    self.status ='draft'
    self.save
  end
  
  def publish(tm)
    self.status = 'published'
    self.published_at = tm
  end

  def duplicate!
    new_post = self.clone

    [ :body, :job_status ].each do |fld|
        new_post.send("#{fld}=",self.send(fld))
    end
    new_post.created_at = nil
    new_post.updated_at = nil
    new_post.title = "(COPY) " + self.title.to_s
    new_post.permalink = nil
    new_post.published_at = nil
    new_post.status = 'draft'
    new_post.save
    new_post
  end


  def make_draft
    self.status = 'draft'  
  end
  
  def published?
    self.status.to_s =='published' && self.published_at && self.published_at < Time.now
  end
  
  
end
