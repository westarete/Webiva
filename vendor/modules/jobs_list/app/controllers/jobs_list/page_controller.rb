# Copyright (C) 2009 Pascal Rettig.

class JobsList::PageController < ParagraphController
  
  editor_header "Jobs List Paragraphs"

  editor_for :entry_list, :name => 'Jobs List Entry List', :features => ['jobs_list_entry_list'],
                       :inputs => { :type =>       [[:list_type, 'List Type (Category,Tags,Archive)', :path]],
                                    :identifier => [[:list_type_identifier, 'Type Identifier - Category, Tag, or Month name', :path]],
                                    :category =>   [[:category, 'Category Name', :path ]],
                                    :tag =>        [[:tag, "Tag Name", :path ]],
                                    :jobs_list =>  [[:jobs_list_id,'Jobs List ID',:path]]
                                  },
                       :outputs => [[:category, 'Selected Category', :jobs_list_category_id]]

  
  editor_for :entry_detail, :name => 'Jobs List Entry Detail', :features => ['jobs_list_entry_detail'],
                       :inputs => { :input => [[ :post_permalink, 'Jobs List Post Permalink', :path ]],
                                    :jobs_list => [[:jobs_list_id,'Jobs List ID',:path ]]
                                  },
                       :outputs => [[:content_id, 'Content Identifier', :content],
                                    [:content_node_id, 'Content Node', :content_node_id ],
                                    [:post, 'Jobs List Post', :post_id ]]

  editor_for :categories, :name => 'Jobs List Categories' ,:features => ['jobs_list_categories'],
                        :inputs => [[:category, 'Selected Category', :jobs_list_category_id]]
 
  class EntryListOptions < HashModel
    attributes :jobs_list_id => 0, :items_per_page => 10, :detail_page => nil, :list_page_id => nil, :include_in_path => nil, :category => nil, :limit_by => 'category', :jobs_list_ids => [], :skip_total => false, :skip_page => false, :order => 'date'

    integer_array_options :jobs_list_ids

    boolean_options :skip_total, :skip_page

    def detail_page_id
      self.detail_page
    end

    integer_options :jobs_list_id, :items_per_page, :detail_page
    page_options :detail_page_id, :list_page_id

    options_form(fld(:jobs_list_id, :select, :options => :jobs_list_options),
		 fld(:detail_page, :page_selector,   :description => 'Leave blank to use canonical content url'),
     fld(:list_page_id, :page_selector,  :description => 'Leave blank to use the current page as the list page'),
   	 fld(:items_per_page, :select, :options => (1..50).to_a),
     fld('Advanced Options',:header),
     fld(:jobs_list_ids, :ordered_array, :options => :jobs_list_name_options, :label => 'For multiple jobs_lists',:description => 'Leave blank to show all jobs lists'),
     fld(:order,:select,:options => [['Newest','date'],['Rating','rating']]),
     fld(:limit_by,:radio_buttons,:label => 'Limit to',:options => [[ 'Categories','category'],['Tags','tag']]),
     fld(:category,:text_field,:label => "Limit to",:description => "Comma separated list of categories or tags"),
     fld(:skip_total, :yes_no, :description => "Set to yes for paragraphs without pagination or for jobs lists\n with a large number (>1000) of posts to speed rendering"),
     fld(:skip_page, :yes_no, :description => "Set to yes to skip looking at the current page number\nuseful for framework paragraphs")
    
		 )

    def jobs_list_name_options
      JobsList::JobsListJobsList.find_select_options(:all,:order=>'name')
    end

    def jobs_list_options
      [['---Use Page Connection---'.t,'']] + [['Multiple Jobs Lists'.t,-1]] + JobsList::JobsListJobsList.find_select_options(:all,:order=>'name')
    end

    def include_in_path_options
      [["Include Jobs List ID in detail path", "jobs_list_id"]]
    end
  end
    
  class EntryDetailOptions < HashModel
    attributes :jobs_list_id => 0, :list_page_id => nil, :include_in_path => nil
      
    integer_options :jobs_list_id
    page_options :list_page_id

    options_form(fld(:jobs_list_id, :select, :options => :jobs_list_options),
		 fld(:list_page_id, :page_selector),
		 fld(:include_in_path, :select, :options => :include_in_path_options)
		 )

    canonical_paragraph "JobsList::JobsListJobsList", :jobs_list_id, :list_page_id => :list_page_id

    def jobs_list_options
      [['---Use Page Connection---'.t,'']] + JobsList::JobsListJobsList.find_select_options(:all,:order=>'name')
    end

    def include_in_path_options
      [["Include Jobs List ID in detail path", "jobs_list_id"]]
    end
  end
  
  class CategoriesOptions < HashModel
    attributes :jobs_list_id => nil, :list_page_id => nil, :detail_page_id => nil

    integer_options :jobs_list_id
    page_options :list_page_id, :detail_page_id

    validates_presence_of :jobs_list_id, :list_page_id, :detail_page_id

    options_form(fld(:jobs_list_id, :select, :options => :jobs_list_options),
		 fld(:list_page_id, :page_selector),
		 fld(:detail_page_id, :page_selector)
		 )

    def jobs_list_options
      [['---Select Jobs List---'.t,'']] + JobsList::JobsListJobsList.find_select_options(:all,:order=>'name')
    end
  end
end
