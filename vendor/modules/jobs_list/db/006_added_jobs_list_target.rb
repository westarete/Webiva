# Copyright (C) 2009 Pascal Rettig.

class AddedJobsListTarget < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :is_user_jobs_list, :boolean, :default => false
    add_column :jobs_list_jobs_lists, :target_type, :string
    add_column :jobs_list_jobs_lists, :target_id, :integer
    add_column :jobs_list_jobs_lists, :created_at, :datetime
    
    
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :is_user_jobs_list
    remove_column :jobs_list_jobs_lists, :target_type
    remove_column :jobs_list_jobs_lists, :target_id
    remove_column :jobs_list_jobs_lists, :created_at
  end

end
