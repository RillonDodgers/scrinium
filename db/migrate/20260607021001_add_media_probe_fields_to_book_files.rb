class AddMediaProbeFieldsToBookFiles < ActiveRecord::Migration[8.1]
  def change
    add_column :book_files, :duration_seconds, :integer
    add_column :book_files, :bit_rate, :integer
    add_column :book_files, :codec, :string
    add_column :book_files, :sample_rate, :integer
    add_column :book_files, :channels, :integer
    add_column :book_files, :media_metadata, :json, default: {}, null: false
    add_column :book_files, :chapters, :json, default: [], null: false
  end
end
