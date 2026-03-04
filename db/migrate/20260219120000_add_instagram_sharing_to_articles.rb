# frozen_string_literal: true

class AddInstagramSharingToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :instagram_shared_at, :datetime
    add_column :articles, :instagram_media_id, :string
  end
end
