# Copyright (C) 2009 Pascal Rettig.

class AddedJobsListExcerptTitle < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_post_revisions, :preview_title, :string
  end

  def self.down
    remove_column :jobs_list_post_revisions, :preview_title
  end

end
