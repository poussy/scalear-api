require 'test_helper'

class SharedItemTest < ActiveSupport::TestCase

  def setup
    @shared_item = shared_items(:shared_item1)
  end

  test "invalid without data" do
    assert @shared_item.valid?
    @shared_item.data = nil
    assert_not @shared_item.valid?
    assert_match /can't be blank/, @shared_item.errors["data"].join
    
  end

  test "invalid without shared_by_id" do
    @shared_item.shared_by_id = nil
    assert_not @shared_item.valid?
    assert_match /can't be blank/, @shared_item.errors["shared_by_id"].join
  end

  test "invalid without shared_with_id" do
    @shared_item.shared_with_id = nil
    assert_not @shared_item.valid?
    assert_match /can't be blank/, @shared_item.errors["shared_with_id"].join
    
  end
  


  test "should return sharer email" do
    assert_equal @shared_item.sharer_email, "okashaaa@gmail.com"
  end

  test "should return name" do
    assert_equal @shared_item.name, "Data shared by okashaaa@gmail.com"
  end

  test "return true if contains data" do
    assert @shared_item.has_data?
  end

  test "return false if no data present" do
    @shared_item.data.each do |key, value|
      @shared_item.data[key] = []

    end
    @shared_item.save
    assert_not @shared_item.has_data?
  end

  test " should delete all occurences of module, quiz, lecture or link from shared items" do
    ## delete_dependent(type, id, user_id)
    SharedItem.delete_dependent("modules", 4, 4)
    ## now module 4 is not in any shared item data
    SharedItem.all.each do |item|
      assert_not item.data["modules"].include? 4
    end
    
  end


  test " should delete the entire shared_item if no data is present" do
    SharedItem.delete_dependent("modules", 2, 4)
    SharedItem.delete_dependent("lectures", 3, 4)
    SharedItem.delete_dependent("quizzes", 1, 4)
    SharedItem.delete_dependent("customlinks", 1, 4)
    ## now we deleted all data in shared item with id == 2
    SharedItem.all.each do |item|
      assert_equal SharedItem.where(id: 2).size, 0
    end
    
  end
  

end
