
class JobsList::AdminController < ModuleController

  component_info 'JobsList', :description => 'Jobs List support', 
                              :access => :public
                              
  # Register a handler feature
  register_permission_category :jobs_list, "JobsList" ,"Permissions related to Jobs List"
  
  register_permissions :jobs_list, [ [ :manage, 'Manage Jobs List', 'Manage Jobs List' ],
                                  [ :config, 'Configure Jobs List', 'Configure Jobs List' ]
                                  ]
  cms_admin_paths "options",
     "Jobs List Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit 'jobs_list_config'

  public 
 
  def options
    cms_page_path ['Options','Modules'],"Jobs List Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Jobs List module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
   # Options attributes 
   # attributes :attribute_name => value
  
  end

end
