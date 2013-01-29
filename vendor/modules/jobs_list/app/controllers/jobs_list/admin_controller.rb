#Copyright (C) 2009 Pascal Rettig.

class JobsList::AdminController < ModuleController
  permit 'jobs_list_config'

  component_info('JobsList',
                 :description => 'Add Jobs List Content Feature',
                 :access => :public,
                 :dependencies => [ 'feedback'] )


  content_model :jobs_list

  register_handler :structure, :wizard, "JobsList::AddJobsListWizard"
  register_handler :feed, :rss, "JobsList::RssHandler"
  register_handler :feed, :rss, "JobsList::MultipleRssHandler"
  register_handler :mail_manager, :generator, "JobsList::ManageController"

  content_action  'Create a new Jobs List', { :controller => '/jobs_list/admin', :action => 'create' }, :permit => 'jobs_list_config'

  register_permission_category :jobs_list, "Jobs List" ,"Permissions for Writing Jobs Lists"

  register_permissions :jobs_list, [ [ :config, 'Jobs List Configure', 'Can Configure Jobs Lists'],
                                [ :writer, 'Jobs Lists Writer', 'Can Write Jobs Lists'],
                                [ :user_jobs_lists, 'User Jobs Lists Editor', 'Can Edit User Jobs Lists' ]
  ]

  public

  def self.get_jobs_list_info
    info = JobsList::JobsListJobsList.find(:all, :order => 'name', :conditions => { :is_user_jobs_list => false }).collect do |jobs_list|
      {:name => jobs_list.name,:url => { :controller => '/jobs_list/manage', :path => jobs_list.id } ,:permission => { :model => jobs_list, :permission =>  :edit_permission, :base => :jobs_list_writer  }, :icon => 'icons/content/model.gif' }
    end
    @user_jobs_lists = JobsList::JobsListJobsList.count(:all,:conditions => {:is_user_jobs_list => true })
    if @user_jobs_lists > 0
      info << { :name => 'Site Jobs Lists', :url => { :controller => '/jobs_list/manage', :action => 'list' },:permission => 'jobs_list_user_jobs_lists', :icon => 'icons/content/model.gif' }
    end
    info
  end

  def create
    cms_page_info [ ["Content",url_for(:controller => '/content') ], "Create a new Jobs List"], "content"

    @jobs_list = JobsList::JobsListJobsList.new(params[:jobs_list] || { :add_to_site => true })

    if(request.post? && params[:jobs_list])
      if(@jobs_list.save)
        if !@jobs_list.add_to_site.blank?
          @version = SiteVersion.current
          redirect_to JobsList::AddJobsListWizard.wizard_url.merge(:jobs_list_id => @jobs_list.id, :version => @version.id)
          return
        else
          redirect_to :controller => '/jobs_list/manage', :path => @jobs_list.id
          return
        end
      end
    end

  end

end
