class AddContentModelToJobsList < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :content_model_id, :integer
    add_column :jobs_list_jobs_lists, :content_publication_id, :integer
    add_column :jobs_list_posts, :data_model_id, :integer
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :content_model_id
    remove_column :jobs_list_jobs_lists, :content_publication_id
    remove_column :jobs_list_posts, :data_model_id
  end
end
