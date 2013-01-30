# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::JobsListCategory do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types

  before(:each) do
    @jobs_list = JobsList::JobsListJobsList.create :name => 'Test Jobs List', :content_filter => 'full_html'
    @category = @jobs_list.jobs_list_categories.build
  end

  it "category should not be valid" do
    @category.should_not be_valid
  end
  
  it "category should be createable with just a name and jobs_list id" do
    @category.name = "Test Category"
    @category.should be_valid
  end

end
