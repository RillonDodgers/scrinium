class AddRichMetadataToBooks < ActiveRecord::Migration[8.1]
  def change
    change_table :books, bulk: true do |t|
      t.integer :hardcover_id
      t.string :hardcover_slug
      t.string :subtitle
      t.text :description
      t.date :release_date
      t.integer :release_year
      t.integer :pages
      t.decimal :average_rating, precision: 5, scale: 3
      t.integer :ratings_count
      t.json :ratings_distribution, null: false, default: {}
      t.decimal :series_position, precision: 8, scale: 2
    end

    add_index :books, :hardcover_id
    add_index :books, :hardcover_slug
  end
end
