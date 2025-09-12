class AddMediaUrLsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :image_url, :string
    add_column :articles, :file_url, :string
    add_column :articles, :video_embed_url, :string
  end
end
