class AddJobsListOptions < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :options_data, :text
    add_column :jobs_list_categories, :permalink, :string
    add_column :jobs_list_categories, :long_title, :string
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :options_data
    remove_column :jobs_list_categories, :permalink
    remove_column :jobs_list_categories, :long_title
  end
end
