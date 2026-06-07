class CreateBookMetadataTags < ActiveRecord::Migration[8.1]
  def change
    create_table :book_metadata_tags do |t|
      t.references :book, null: false, foreign_key: true
      t.references :metadata_tag, null: false, foreign_key: true
      t.integer :count, null: false, default: 0
      t.decimal :spoiler_ratio, precision: 5, scale: 4, null: false, default: 0

      t.timestamps
    end

    add_index :book_metadata_tags, [ :book_id, :metadata_tag_id ], unique: true
  end
end
