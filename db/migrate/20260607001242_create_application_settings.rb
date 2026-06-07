class CreateApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :application_settings do |t|
      t.boolean :singleton_guard, null: false, default: true
      t.text :hardcover_api_token

      t.timestamps
    end

    add_index :application_settings, :singleton_guard, unique: true
  end
end
