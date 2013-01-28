# Copyright (C) 2009 Pascal Rettig.

class MoreAddedJobsListFeatures < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_post_revisions, :embedded_media, :text
  end

  def self.down
    remove_column :jobs_list_post_revisions, :embedded_media
  end

end
