# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe JobsList::JobsListJobsList do


  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types

  before(:each) do
    @jobs_list = JobsList::JobsListJobsList.new
  end
  

  it "jobs list should not be valid" do
    @jobs_list.should_not be_valid
  end
  
  it "jobs list should be createable with just a name and filter" do
    @jobs_list.name = "Test Jobs List"
    @jobs_list.content_filter = 'full_html'
    @jobs_list.should be_valid
  end
  
  it "jobs list should create a content type" do
    @jobs_list.name = "Test Jobs List"
    @jobs_list.content_filter = 'full_html'
    lambda {
      @jobs_list.save
    }.should change { ContentType.count  }.by(1)
    
    ct = ContentType.find(:last)
    
    ct.content_name.should == "Test Jobs List"
    ct.container_type.should == 'JobsList::JobsListJobsList'
    ct.container_id.should == @jobs_list.id
    ct.content_type.should == "JobsList::JobsListPost"
    ct.title_field.should == 'title'
  end

end
