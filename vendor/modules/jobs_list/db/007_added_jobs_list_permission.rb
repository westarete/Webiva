# Copyright (C) 2009 Pascal Rettig.

class AddedJobsListPermission < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :edit_permission, :boolean, :default => false
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :edit_permission
  end

end
