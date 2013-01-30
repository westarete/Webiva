# Copyright (C) 2009 Pascal Rettig.

class AddedJobsListFeatures < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_jobs_lists, :site_template_id, :integer

  end

  def self.down
    remove_column :jobs_list_jobs_lists, :site_template_id

  end

end
