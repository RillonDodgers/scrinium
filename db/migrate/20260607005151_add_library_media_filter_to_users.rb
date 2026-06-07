class AddLibraryMediaFilterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :library_media_filter, :string, null: false, default: "ebooks"
  end
end
