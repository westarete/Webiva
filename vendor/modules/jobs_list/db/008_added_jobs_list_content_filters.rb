
class AddedJobsListContentFilters < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :content_filter, :string

    execute "UPDATE jobs_list_jobs_lists SET content_filter = 'full_html' WHERE 1"
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :content_filter
  end
end
