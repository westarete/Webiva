# Copyright (C) 2009 Pascal Rettig.

class InitialJobsListSetup < ActiveRecord::Migration
  def self.up

    # Need to define default weight metric
    create_table :jobs_list_jobs_lists , :force => true do |t|
      t.column :name, :string
      t.column :description, :string
    end

    create_table :jobs_list_post_revisions, :force => true do |t|
      t.column :jobs_list_post_id, :integer
      t.column :title, :string
      t.column :status, :string, :default => 'active'
      t.column :body, :text , :limit => 2.megabytes

      t.column :body_html, :text , :limit => 2.megabytes
      t.column :job_status, :string, :default => 'Active'
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  

    add_index :jobs_list_post_revisions, :jobs_list_post_id, :name => 'post'

    create_table :jobs_list_posts, :force => true do |t|
      t.column :jobs_list_jobs_list_id, :integer
      t.column :jobs_list_post_revision_id, :integer
      t.column :permalink, :string
      t.column :status, :string, :default => 'draft'
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :published_at, :datetime
    end

    add_index :jobs_list_posts,[ :jobs_list_jobs_list_id, :created_at ], :name => 'jobs_list'


    create_table :jobs_list_categories, :force => true do |t|
      t.column :jobs_list_jobs_list_id, :integer
      t.column :name, :string
    end
  
    
    add_index :jobs_list_categories,:jobs_list_jobs_list_id, :name => 'jobs_list'

    create_table :jobs_list_posts_categories, :force => true do |t|
      t.column :jobs_list_post_id, :integer
      t.column :jobs_list_category_id, :integer
    end

    add_index :jobs_list_posts_categories, :jobs_list_post_id, :name => 'jobs_list_post'
    add_index :jobs_list_posts_categories, :jobs_list_category_id, :name => 'jobs_list_category_id'

  end

  def self.down
    drop_table :jobs_list_jobs_lists
    drop_table :jobs_list_posts
    drop_table :jobs_list_post_revisions
    drop_table :jobs_list_categories
    drop_table :jobs_list_posts_categories
  end

end
