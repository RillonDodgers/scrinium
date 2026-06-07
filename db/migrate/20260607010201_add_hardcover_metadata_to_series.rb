class AddHardcoverMetadataToSeries < ActiveRecord::Migration[8.1]
  def change
    change_table :series, bulk: true do |t|
      t.integer :hardcover_id
      t.integer :books_count
    end

    add_index :series, :hardcover_id
  end
end
