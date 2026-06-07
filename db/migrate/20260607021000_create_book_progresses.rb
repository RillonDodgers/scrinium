class CreateBookProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :book_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.references :epub_book_file, foreign_key: { to_table: :book_files }
      t.references :m4b_book_file, foreign_key: { to_table: :book_files }
      t.string :epub_location
      t.decimal :audio_position_seconds, precision: 12, scale: 3, default: 0, null: false
      t.string :last_mode

      t.timestamps
    end

    add_index :book_progresses, [ :user_id, :book_id ], unique: true
  end
end
