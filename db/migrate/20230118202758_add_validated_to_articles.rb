class AddValidatedToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :validated, :boolean
  end
end
