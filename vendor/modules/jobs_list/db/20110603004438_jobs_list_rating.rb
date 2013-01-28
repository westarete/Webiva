class JobsListRating < ActiveRecord::Migration
  def self.up
    add_column :jobs_list_posts, :rating, :decimal, :precision => 14, :scale => 2, :default => 0.0
  end

  def self.down
    remove_column :jobs_list_posts, :rating
  end
end
