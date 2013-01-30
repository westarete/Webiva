require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::ManageController do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :mail_templates

  before(:each) do
    mock_editor
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
    @category = @jobs_list.jobs_list_categories.create :name => 'Test Category'
    @post = @jobs_list.jobs_list_posts.new(:title => 'Test Post',:body => 'Test Body')
    @post.save
  end

  it "should be able to render index page" do
    get 'index', :path => [@jobs_list.id]
  end

  it "should handle post table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:post_table) do |args|
      args[:path] = [@jobs_list.id]
      post 'post_table', args
    end
  end

  it "should be able to render index page" do
    get 'generate_mail', :path => [@jobs_list.id]
  end

  it "should handle generate post table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:generate_post_table) do |args|
      args[:path] = [@jobs_list.id]
      post 'display_generate_post_table', args
    end
  end

  it "should be able to delete a jobs list post" do
    assert_difference 'JobsList::JobsListPost.count', -1 do
      post 'post_table', :path => [@jobs_list.id], :table_action => 'delete', :post => {@post.id.to_s => 1}
    end
  end

  it "should be able to publish a jobs list post" do
    @post.status.should == 'draft'
    @post.published_at.should be_nil

    assert_difference 'JobsList::JobsListPost.count', 0 do
      post 'post_table', :path => [@jobs_list.id], :table_action => 'publish', :post => {@post.id.to_s => 1}
    end

    @post.reload
    @post.status.should == 'published'
    @post.published_at.should_not be_nil
  end

  it "should be able to render generate_mail" do
    get 'generate_mail', :path => [@jobs_list.id]
  end

  it "should be able to render generate_mail_generate" do
    get 'generate_mail_generate', :path => [@jobs_list.id], :post_id => @post.id, :opts => {:align => 'left', :header => 'above'}
  end

  it "should be able to render generate_categories" do
    get 'generate_categories', :path => [@jobs_list.id]
  end

  it "should be able to create a mail template from a post" do
    assert_difference 'MailTemplate.count', 1 do
      post 'mail_template', :path => [@jobs_list.id, @post.id]
    end

    @template = MailTemplate.find(:last)
    response.should redirect_to(:controller => '/mail_manager', :action => 'edit_template', :path => @template.id)
  end

  it "should be able to render create a post" do
    get 'post', :path => [@jobs_list.id]
  end

  it "should be able to render edit a post" do
    get 'post', :path => [@jobs_list.id, @post.id]
  end

  it "should be able to create a post" do
    assert_difference 'JobsList::JobsListPost.count', 1 do
      post 'post', :path => [@jobs_list.id], :entry => {:title => 'New Jobs List Title', :body => 'New Jobs List Body'}, :update_entry => {:status => 'draft'}
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @new_post = JobsList::JobsListPost.find :last
    @new_post.published_at.should be_nil
    @new_post.status.should == 'draft'
  end

  it "should be able to create a post and publish it" do
    JobsList::JobsListJobsList.should_receive(:find).any_number_of_times.and_return(@jobs_list)

    assert_difference 'JobsList::JobsListPost.count', 1 do
      post 'post', :path => [@jobs_list.id], :entry => {:title => 'New Jobs List Title', :body => 'New Jobs List Body'}, :update_entry => {:status => 'publish_now'}
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @new_post = JobsList::JobsListPost.find :last
    @new_post.status.should == 'published'
    @new_post.published_at.should_not be_nil
  end

  it "should be able to create a post and publish it" do
    JobsList::JobsListJobsList.should_receive(:find).any_number_of_times.and_return(@jobs_list)

    published_at = 1.hour.ago

    assert_difference 'JobsList::JobsListPost.count', 1 do
      post 'post', :path => [@jobs_list.id], :entry => {:title => 'New Jobs List Title', :body => 'New Jobs List Body', :published_at => published_at}, :update_entry => {:status => 'post_date'}
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @new_post = JobsList::JobsListPost.find :last
    @new_post.status.should == 'published'
    @new_post.published_at.to_i.should == published_at.to_i
  end

  it "should be able to edit a post" do
    assert_difference 'JobsList::JobsListPost.count', 0 do
      post 'post', :path => [@jobs_list.id, @post.id], :entry => {:title => 'New Jobs List Title', :body => 'Test Body'}, :update_entry => {:status => 'draft'}
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @post.reload
    @post.title.should == 'New Jobs List Title'
  end

  it "should be able to edit a post and add categories" do
    assert_difference 'JobsList::JobsListPost.count', 0 do
      post 'post', :path => [@jobs_list.id, @post.id], :entry => {:title => 'New Jobs List Title'}, :update_entry => {:status => 'draft'}, :categories => [@category.id]
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @post.reload
    @post.title.should == 'New Jobs List Title'

    @post_category = JobsList::JobsListPostsCategory.find_by_jobs_list_post_id_and_jobs_list_category_id @post.id, @category.id
    @post_category.should_not be_nil
  end

  it "should be able to edit a post and delete categories" do
    @post.set_categories! [@category.id]
    @post.reload
    @post_category = JobsList::JobsListPostsCategory.find_by_jobs_list_post_id_and_jobs_list_category_id @post.id, @category.id
    @post_category.should_not be_nil

    assert_difference 'JobsList::JobsListPost.count', 0 do
      post 'post', :path => [@jobs_list.id, @post.id], :entry => {:title => 'New Jobs List Title'}, :update_entry => {:status => 'draft'}, :categories => []
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @post.reload
    @post.title.should == 'New Jobs List Title'

    @post_category = JobsList::JobsListPostsCategory.find_by_jobs_list_post_id_and_jobs_list_category_id @post.id, @category.id
    @post_category.should be_nil
  end

  it "should be able to render delete a jobs list" do
    get 'delete', :path => [@jobs_list.id]
  end

  it "should be able to delete a jobs list" do
    assert_difference 'JobsList::JobsListJobsList.count', -1 do
      post 'delete', :path => [@jobs_list.id], :destroy => 'yes'
    end

    response.should redirect_to(:controller => '/content', :action => 'index')
  end

  it "should be able to add category" do
    assert_difference 'JobsList::JobsListCategory.count', 1 do
      post 'add_category', :path => [@jobs_list.id], :name => 'New Category'
    end

    @new_category = JobsList::JobsListCategory.find :last
    @new_category.name.should == 'New Category'
  end

  it "should not be able to add same category" do
    assert_difference 'JobsList::JobsListCategory.count', 0 do
      post 'add_category', :path => [@jobs_list.id], :name => 'Test Category'
    end
  end

  it "should not be able to render edit a jobs list" do
    get 'configure', :path => [@jobs_list.id]
  end

  it "should not be able to edit a jobs list" do
    assert_difference 'JobsList::JobsListJobsList.count', 0 do
      post 'configure', :path => [@jobs_list.id], :jobs_list => {:name => 'New Jobs List Name'}
    end

    response.should redirect_to(:action => 'index', :path => @jobs_list.id)

    @jobs_list.reload
    @jobs_list.name.should == 'New Jobs List Name'
  end

  it "should not be able to render add_tags" do
    get 'add_tags', :path => [@jobs_list.id], :existing_tags => ''
  end

  it "should be able to render list page" do
    get 'list'
  end

  it "should handle jobs list table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:jobs_list_list_table) do |args|
      post 'display_jobs_list_list_table', args
    end
  end

end
