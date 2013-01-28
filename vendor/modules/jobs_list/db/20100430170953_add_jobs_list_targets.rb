class AddJobsListTargets < ActiveRecord::Migration
  def self.up
    create_table :jobs_list_targets do |t|
      t.string :target_type
      t.integer :content_type_id
    end

    add_column :jobs_list_jobs_lists, :jobs_list_target_id, :integer
    
  end

  def self.down
    drop_table :jobs_list_targets
    remove_column :jobs_list_jobs_lists, :jobs_list_target_id
  end
end
