class AddGuidToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :guid, :integer
  end
end
