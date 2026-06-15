class CreateTheaters < ActiveRecord::Migration[8.1]
  def change
    create_table :theaters do |t|
      t.string :name
      t.string :location

      t.timestamps
    end
  end
end
