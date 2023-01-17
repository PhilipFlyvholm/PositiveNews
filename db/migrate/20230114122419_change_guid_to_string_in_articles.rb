class ChangeGuidToStringInArticles < ActiveRecord::Migration[7.0]
  def change
    change_column :articles, :guid, :string
  end
end
