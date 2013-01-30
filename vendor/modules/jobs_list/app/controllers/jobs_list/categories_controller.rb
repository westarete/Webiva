# Copyright (C) 2009 Pascal Rettig.


class JobsList::CategoriesController < ModuleController
  
  permit 'jobs_list_writer'

  component_info 'Jobs List'

  # need to include 
   include ActiveTable::Controller   
   active_table :category_table,
                JobsList::JobsListCategory,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, 'jobs_list_categories.name'),
                  hdr(:static, 'jobs_list_posts_count',:label => 'Entries')
                ]

    def category_table(display=true)

      @jobs_list = JobsList::JobsListJobsList.find(params[:path][0]) unless @jobs_list


      if(request.post? && params[:table_action] && params[:category].is_a?(Hash)) 
        case params[:table_action]
        when 'delete':
          params[:category].each do |entry_id,val|
            JobsList::JobsListCategory.destroy(entry_id.to_i)
          end
        end
      end

      @active_table_output = category_table_generate(params, :order => 'name DESC', 
                                        :conditions => ['jobs_list_categories.jobs_list_jobs_list_id = ?',@jobs_list.id ],
                                        :include => :jobs_list_posts_categories )

      render :partial => 'category_table' if display
    end

    def index
        @jobs_list = JobsList::JobsListJobsList.find(params[:path][0])

       cms_page_info [ ["Content",url_for(:controller => '/content') ], [ "%s",url_for(:controller => '/jobs_list/manage', :action => 'index', :path => @jobs_list.id),@jobs_list.name], 'Manage Categories'], "content"
        
       category_table(false)

      
    end

    def create_category
        @jobs_list = JobsList::JobsListJobsList.find(params[:path][0])
  
        cat = @jobs_list.jobs_list_categories.create(:name => params[:name] )
  
        
        category_table(true)
    end
end
