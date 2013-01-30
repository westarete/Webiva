# Copyright (C) 2009 Pascal Rettig.



class JobsList::EditController < ParagraphController

  editor_header 'Jobs List Paragraphs'
  
  editor_for :list, :name => "User Jobs List List", :feature => :jobs_list_edit_list,
                       :inputs => { :input => [ [ :container, 'Jobs List Target', :target] ],
                                    :target_url => [ [:target_url, "Target URL", :path ] ] }

  editor_for :write, :name => "User Jobs List Write Post", :feature => :jobs_list_edit_write,
                       :inputs => { :target => [ [ :container, 'Jobs List Target', :target] ],
                                    :post => [ [ :post_permalink, 'Jobs List Post Permalink', :path ] ],
                                    :target_url => [ [ :target_url, "Target URL", :path ]] }
  


  class ListOptions < HashModel
    attributes :auto_create => true, :jobs_list_name => '%s Jobs List',:edit_page_id => nil
    
    page_options :edit_page_id
    
    boolean_options :auto_create
  end
  
  class WriteOptions < HashModel
    attributes :list_page_id => nil
    
    page_options :list_page_id
  end

end
