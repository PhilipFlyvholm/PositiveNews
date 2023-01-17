class RemoveStatusToArticles < ActiveRecord::Migration[7.0]
  def change
    remove_column :articles, :status
  end
end
