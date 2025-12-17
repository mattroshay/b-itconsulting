class AddLinkedInSharingToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :linkedin_shared_at, :datetime
  end
end
