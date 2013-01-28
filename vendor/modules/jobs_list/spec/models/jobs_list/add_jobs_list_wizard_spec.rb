# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe JobsList::AddJobsListWizard do


  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :site_nodes, :page_paragraphs,:page_revisions

  before(:each) do
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List',:content_filter => 'full_html')
  end

  it "should add the jobs list to site" do
    root_node = SiteVersion.default.root_node.add_subpage('tester')
    wizard = JobsList::AddJobsListWizard.new(
                                     :jobs_list_id => @jobs_list.id,
                                     :add_to_id => root_node.id,
                                     :add_to_subpage => 'jobs_list',
                                     :detail_page_url => 'myview',
                                     :number_of_dummy_posts => 0
                                     )
    wizard.run_wizard

    SiteNode.find_by_node_path('/tester/jobs_list').should_not be_nil
    
  end

end
