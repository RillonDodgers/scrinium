class CreateMetadataTags < ActiveRecord::Migration[8.1]
  def change
    create_table :metadata_tags do |t|
      t.integer :hardcover_tag_id
      t.string :category, null: false
      t.string :category_slug, null: false
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :metadata_tags, :hardcover_tag_id, unique: true, where: "hardcover_tag_id IS NOT NULL"
    add_index :metadata_tags, [ :category_slug, :slug ], unique: true
  end
end
