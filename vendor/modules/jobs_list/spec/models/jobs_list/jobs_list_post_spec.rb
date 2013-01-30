# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe JobsList::JobsListPost do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes

  before(:each) do
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
  end
  
  
  it "should create a content_node after create" do
    @jobs_list.should be_valid
    post = JobsList::JobsListPost.new(:jobs_list_jobs_list_id => @jobs_list.id, :title => 'Test Post', :body => 'Testerama',:job_status => 'Anonymous')
    
    post.should be_valid
    
    ContentNode.count.should == 0
    lambda {
      post.save
    }.should change { ContentNode.count  }.by(1)
    JobsList::JobsListPostRevision.count.should == 1
  end

  it "should be able to create and resave a post" do
    @post = @jobs_list.jobs_list_posts.build(:title => 'Tester', :body => 'Body!')
    
    assert_difference "JobsList::JobsListPost.count", 1 do
      @post.save
    end

    JobsList::JobsListPostRevision.count.should == 1
    @revision = JobsList::JobsListPostRevision.find(:last)

    @revision.title.should == 'Tester'
    @post.reload
    @post.title = 'Tester Title 2'
    @post.save

    JobsList::JobsListPostRevision.count.should == 2

    @revision.reload
    @revision.title.should == 'Tester'
    JobsList::JobsListPostRevision.find(:last).title.should == 'Tester Title 2'
  end


end
