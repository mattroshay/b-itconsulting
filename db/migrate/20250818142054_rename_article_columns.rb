class RenameArticleColumns < ActiveRecord::Migration[7.1]
  def change
    rename_column :articles, :name, :title
    rename_column :articles, :body, :content 
  end
end
