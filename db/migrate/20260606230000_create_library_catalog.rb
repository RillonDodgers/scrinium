class CreateLibraryCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :libraries do |t|
      t.string :name, null: false
      t.string :root_path, null: false

      t.timestamps
    end

    add_index :libraries, :name, unique: true
    add_index :libraries, :root_path, unique: true

    create_table :authors do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :authors, :name, unique: true

    create_table :series do |t|
      t.references :author, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :series, [ :author_id, :name ], unique: true

    create_table :books do |t|
      t.references :library, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true
      t.references :series, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end

    add_index :books, [ :library_id, :author_id, :series_id, :title ], unique: true

    create_table :book_files do |t|
      t.references :book, null: false, foreign_key: true
      t.string :format, null: false
      t.string :relative_path, null: false
      t.string :status, null: false, default: "present"
      t.integer :size_bytes, null: false
      t.datetime :mtime, null: false

      t.timestamps
    end

    add_index :book_files, [ :book_id, :format, :relative_path ], unique: true
    add_index :book_files, :relative_path
    add_index :book_files, :status

    create_table :scan_runs do |t|
      t.references :library, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :found_count, null: false, default: 0
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :missing_count, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.text :last_error

      t.timestamps
    end

    add_index :scan_runs, :status
  end
end
