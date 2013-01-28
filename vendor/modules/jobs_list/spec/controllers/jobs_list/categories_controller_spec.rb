require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::CategoriesController do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types

  before(:each) do
    mock_editor
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
  end

  it "should be able to render index page" do
    get 'index', :path => [@jobs_list.id]
  end

  it "should handle table list" do 
    cat = @jobs_list.jobs_list_categories.create(:name => 'Test Category')
    cat.id.should_not be_nil

    # Test all the permutations of an active table
    controller.should handle_active_table(:category_table) do |args|
      args[:path] = [@jobs_list.id]
      post 'category_table', args
    end
  end

  it "should be able to create a jobs list category" do
    assert_difference 'JobsList::JobsListCategory.count', 1 do
      post 'create_category', :path => [@jobs_list.id], :name => 'Test Category'
    end

    @cat = JobsList::JobsListCategory.find(:last)
    @cat.name.should == 'Test Category'
  end

  it "should be able to delete a jobs list category" do
    @cat = @jobs_list.jobs_list_categories.create(:name => 'Test Category')
    @cat.id.should_not be_nil

    assert_difference 'JobsList::JobsListCategory.count', -1 do
      post 'category_table', :path => [@jobs_list.id], :table_action => 'delete', :category => {@cat.id.to_s => 1}
    end
  end
end
