# Copyright (C) 2009 Pascal Rettig.

class JobsList::ManageController < ModuleController
  
  permit 'jobs_list_writer', :except => [ :configure]

  permit 'jobs_list_config', :only => [ :configure, :delete, :import ]

  before_filter :check_view_permission, :except => [ :configure, :delete, :display_jobs_list_list_table, :list, :generate_mail, :generate_mail_generate, :display_generate_post_table, :import ]

  component_info 'JobsList'
  
  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Site Jobs Lists' => { :action => 'list' }
  
  # need to include 
   include ActiveTable::Controller   
   active_table :post_table,
                JobsList::JobsListPost,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, 'jobs_list_post_revisions.title', :label => 'Job Title'),
                  hdr(:options, 'jobs_list_posts.status', :label => 'Publication Status', :options => JobsList::JobsListPost.status_select_options ),
                  :published_at,
                  :permalink,
                  :updated_at,
                  hdr(:options, 'jobs_list_posts_categories.jobs_list_category_id', :label => 'Category', :options => :generate_categories, :display => 'select' )
                ]
                
  def self.mail_manager_generator_handler_info
    {
    :name => "Generate From Jobs List Post",
    :url => { :controller => '/jobs_list/manage',:action => 'generate_mail' }
    }
  end
  
  active_table :generate_post_table,
                JobsList::JobsListPost,
                [ hdr(:icon, '', :width=>20),
                  hdr(:string, 'jobs_list_jobs_lists.name', :label=> 'Jobs List'),
                  hdr(:string, 'jobs_list_post_revisions.title', :label => 'Post Title'),
                  :published_at,
                  :updated_at
                ]

  def display_generate_post_table(display=true)
      @tbl = generate_post_table_generate params, :order => 'jobs_list_posts.published_at DESC',:joins => [ :active_revision, :jobs_list_jobs_list ]
      render :partial =>'generate_post_table' if display
  end
  
  def generate_mail
      display_generate_post_table(false)
      render :partial => 'generate_mail'
  end
  
  def generate_mail_generate
    @post = JobsList::JobsListPost.find(params[:post_id])

    @align = params[:opts][:align] == 'left' ? 'left' : 'right'
    @padding = params[:opts][:align] == 'left' ? 'padding:0 10px 10px 0;' : 'padding:0 0 10px 0px;'
    @img = "<img class='jobs_list_image' src='#{@post.domain_file.url(:small)}' align='#{@align}' style='#{@padding}'>" if params[:opts][:align] != 'none' && @post.domain_file
    
    @title = "<h1 class='jobs_list_title'>#{h(@post.title)}</h1>"

    @post_content = "<div class='jobs_list_entry'>"
    
    if params[:opts][:header] == 'above'
      @post_content += @title + @img.to_s
    else
      @post_content += @img.to_s + @title
    end
    @post_content += "\n<div class='jobs_list_body'>"
    @post_content += @post.body_content + "</div><div class='jobs_list_clear' style='clear:both;'>&nbsp;</div></div>"
  end
            
                
  def generate_categories
    @jobs_list.jobs_list_categories.collect { |cat| [ cat.name, cat.id ] }
  end

  def post_table(display=true)

    active_table_action(:post) do |act,eids| 
      entries = JobsList::JobsListPost.find(eids)
      case act
      when 'delete': entries.map(&:destroy)
      when 'publish': entries.map(&:publish!)
      when 'unpublish': entries.map(&:unpublish!)
      when 'duplicate': entries.map(&:duplicate!)
      end
    end

    @active_table_output = post_table_generate params, :joins => [ :active_revision ], :include => [ :jobs_list_categories ],
      :order => 'jobs_list_posts.updated_at DESC', :conditions => ['jobs_list_posts.jobs_list_jobs_list_id = ?',@jobs_list.id ]


    render :partial => 'post_table' if display
  end

  def index 
     jobs_list_path(@jobs_list)
  
     post_table(false)
  end
  
  def mail_template
     @entry = @jobs_list.jobs_list_posts.find(params[:path][1])
     
     
     @mail_template = MailTemplate.create(:name => @jobs_list.name + ":" + @entry.title,
					  :subject => @entry.title,
					  :body_html => @entry.body,
					  :generate_text_body => true,
					  :body_type => 'html,text')
                                       
    redirect_to :controller => '/mail_manager',:action => 'edit_template', :path => @mail_template.id
  
  end

  def post
     @entry = @jobs_list.jobs_list_posts.find(params[:path][1]) if params[:path][1]

      @header = <<-EOF
        <script>
          var cmsEditorOptions = { #{"content_css: '" + url_for(:controller => '/public', :action => 'stylesheet', :path => [ @jobs_list.site_template_id, Locale.language.code ], :editor => 1) + "'," if !@jobs_list.site_template_id.blank? }
                                   #{"body_class: '" + h(@jobs_list.html_class) + "'," if !@jobs_list.html_class.blank?}
                                   dummy: null
                                 }
        </script>
      EOF
      require_js('cms_form_editor')

     if @entry
       jobs_list_path(@jobs_list,[ 'Edit Job: %s', nil, @entry.title ])
     else
       jobs_list_path(@jobs_list,"Post New Job")
       @entry = @jobs_list.jobs_list_posts.build()
     end
     @selected_category_ids = params[:categories] || @entry.category_ids

     @entry.author = myself.name if @entry.author.blank?

     if request.post? && params[:entry]
        @entry.attributes = params[:entry]

        case params[:update_entry][:status]
        when 'draft':       @entry.make_draft
        when 'publish_now': @entry.publish_now
        when 'preview':     @entry.make_preview
        when 'post_date'
          @entry.publish(params[:entry][:published_at].blank? ? Time.now : (params[:entry][:published_at]))
        end
    
        if @entry.save
          @entry.set_categories!(params[:categories])
          @jobs_list.send_pingbacks(@entry)

          redirect_to :action => 'index', :path => @jobs_list.id
          return 
        end
     end

     @categories = @jobs_list.jobs_list_categories

  end

  def delete
    @jobs_list = JobsList::JobsListJobsList.find(params[:path][0])
    jobs_list_path(@jobs_list,"Delete Jobs List")

    if request.post? && params[:destroy] == 'yes'
        @jobs_list.destroy

        redirect_to :controller => '/content', :action => 'index'
    end
  end

  def add_category
      @category = @jobs_list.jobs_list_categories.create(:name => params[:name])

      if @category.id
        render :partial => 'category', :locals => { :category => @category }
      else
        render :inline => '<script>alert("Category already exists");</script>'
      end

  end
  
  def configure
      @jobs_list = JobsList::JobsListJobsList.find(params[:path][0])
      jobs_list_path(@jobs_list,"Configure Jobs List")
      
      if(request.post? && params[:jobs_list])
        if(@jobs_list.update_attributes(params[:jobs_list]))
          flash[:notice] = 'Updated Configuration'.t
          redirect_to :action => 'index',:path => @jobs_list.id
        end
      end
    
      @site_templates = [['--Select Site Template--',nil]] + SiteTemplate.find_options(:all,:conditions => 'parent_id IS NULL')
  end
  
  def add_tags
      @existing_tags = params[:existing_tags].to_s
      
      @existing_tag_arr = @existing_tags.split(",").collect { |elem| elem.strip }.find_all { |elem| !elem.blank? }
      @cloud = JobsList::JobsListPost.tag_cloud()
      
      render :partial => 'add_tags'
  
  end
  
   active_table :jobs_list_list_table,
                JobsList::JobsListJobsList,
                [ :check,
                  hdr(:string,'jobs_list_jobs_lists.name',:label=> 'Jobs List'),
                  :created_at
                ]
  
  def display_jobs_list_list_table(display=true)
    active_table_action('jobs_list') do |act,bids|
      JobsList::JobsListJobsList.destroy(bids) if act == 'delete'
    end
  
    @tbl = jobs_list_list_table_generate params, :order => 'jobs_list_jobs_lists.created_at DESC', :conditions => ['is_user_jobs_list=1']
    render :partial => 'jobs_list_list_table' if display
  end
  
  def list
    cms_page_path ['Content'], 'Site Jobs Lists'
    display_jobs_list_list_table(false)
  end

  def import
    @jobs_list = JobsList::JobsListJobsList.find(params[:path][0])
    jobs_list_path(@jobs_list,"Import Jobs List")

    @import = ImportOptions.new params[:import]
    @import.wordpress_import_settings = ['comments', 'pages'] unless params[:import]

    if request.post? && @import.valid?
      if params[:commit]
        if @import.import @jobs_list, myself
          redirect_to :action => 'index', :path => [ @jobs_list.id ]
        end
      else
        redirect_to :action => 'index', :path => [ @jobs_list.id ]
      end
    end
  end

  protected
  
  class ImportOptions < HashModel
    attributes :import_file_id => nil, :wordpress_export_file_id => nil, :wordpress_url => nil, :wordpress_username => nil, :wordpress_password => nil, :wordpress_import_settings => [], :rss_url => nil

    domain_file_options :import_file_id, :wordpress_export_file_id

    def validate
      if self.import_file_id.blank? && self.wordpress_export_file_id.blank? && self.wordpress_url.blank? && self.rss_url.blank?
        self.errors.add_to_base 'Import settings not specified'
      elsif ! self.rss_url.blank?
        self.errors.add(:rss_url, 'is invalid') unless URI::regexp(%w(http https)).match(self.rss_url)
      elsif self.import_file_id.blank? && self.wordpress_export_file_id.blank? && ! self.wordpress_url.blank?
        self.errors.add(:wordpress_url, 'is invalid') unless URI::regexp(%w(http https)).match(self.wordpress_url)
        self.errors.add(:wordpress_username, 'is missing') if self.wordpress_username.blank?
        self.errors.add(:wordpress_password, 'is missing') if self.wordpress_password.blank?
      end
    end

    def wordpress_importer
      return @wordpress_importer if @wordpress_importer
      @wordpress_importer = JobsList::WordpressImporter.new
      @wordpress_importer.import_comments = self.wordpress_import_settings.include?('comment')
      @wordpress_importer.import_pages = self.wordpress_import_settings.include?('pages')
      @wordpress_importer
    end

    def rss_importer
      @rss_importer ||= JobsList::RssImporter.new
    end

    def import(jobs_list, user)
      if self.import_file
        jobs_list.import_file(self.import_file, user)
      elsif ! self.rss_url.blank?
        self.rss_importer.jobs_list = jobs_list
        if self.rss_importer.import_feed(self.rss_url) 
          self.errors.add(:rss_url, 'failed to import feed') unless self.rss_importer.import
        else
          self.errors.add(:rss_url, 'is invalid')
        end
      elsif self.wordpress_export_file
        self.wordpress_importer.jobs_list = jobs_list
        self.wordpress_importer.import_file(self.wordpress_export_file)
        self.errors.add(:wordpress_export_file_id, self.wordpress_importer.error) unless self.wordpress_importer.import
      elsif ! self.wordpress_url.blank?
        self.wordpress_importer.jobs_list = jobs_list
        unless self.wordpress_importer.import_site(self.wordpress_url, self.wordpress_username, self.wordpress_password)
          if self.wordpress_importer.error == 'Login failed'
            self.errors.add(:wordpress_username, 'is invalid')
            self.errors.add(:wordpress_password, 'is invalid')
          else
            self.errors.add(:wordpress_url, 'is invalid')
            self.errors.add_to_base(self.wordpress_importer.error)
          end
        end

        unless self.wordpress_importer.error
          self.errors.add_to_base(self.wordpress_importer.error) unless self.wordpress_importer.import
        end
      end

      self.errors.length > 0 ? false : true
    end
  end

  def jobs_list_path(jobs_list,path=nil)
    base = ['Content']
    base << 'Site Jobs Lists' if jobs_list.is_user_jobs_list?
    if path
      cms_page_path (base + [[ "%s",url_for(:action => 'index',:path => jobs_list.id),jobs_list.name ]]),path
    else
      cms_page_path base,[ "%s",nil,jobs_list.name ]
    end 
  end


  def check_view_permission
    @jobs_list ||= JobsList::JobsListJobsList.find(params[:path][0])

    if(!myself.has_role?(:jobs_list_config) && @jobs_list.edit_permission?)
      if !myself.has_role?('edit_permission',@jobs_list)
        deny_access!
        return
      end
    end
  end



end
