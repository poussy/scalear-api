class CreateSamlDomains < ActiveRecord::Migration[5.1]
  def change
    create_table :saml_domains do |t|
      t.text :descr
      t.text :title
      t.text :auth
      t.text :keywords
      t.text :scope
      t.text :entityID
      t.text :dataType
      t.text :hidden
      t.text :icon

      t.timestamps
    end
  end
end
