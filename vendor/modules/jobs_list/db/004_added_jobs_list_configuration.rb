# Copyright (C) 2009 Pascal Rettig.

class AddedJobsListConfiguration < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :html_class, :string
  end

  def self.down
    remove_column :jobs_list_jobs_lists, :html_class
  end

end
