class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.string :name
      t.string :chinese_name
      t.string :description
      t.integer :series
      t.string :condition
      t.integer :form
      t.integer :subform
      t.integer :target
      t.string :material
      t.string :formula
      t.string :effect
      t.belongs_to :rule

      t.timestamps null: false
    end
  end
end
