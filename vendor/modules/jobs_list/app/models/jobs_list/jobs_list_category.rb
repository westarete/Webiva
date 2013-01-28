# Copyright (C) 2009 Pascal Rettig.

class JobsList::JobsListCategory < DomainModel

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'jobs_list_jobs_list_id'

  belongs_to :jobs_list_jobs_list

  has_many :jobs_list_posts_categories, :class_name => 'JobsList::JobsListPostsCategory', :dependent => :delete_all




end
