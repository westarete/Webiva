
class AddedJobsListTrackback < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :trackback, :boolean, :default => true
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :trackback
  end
end
