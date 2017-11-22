class CustomLinksController < ApplicationController
  load_and_authorize_resource
  
  
  def update
    @link = CustomLink.find(params[:id])
    if @link.update_attributes(custom_link_params)
      render json: {:notice => I18n.t('controller_msg.link_successfully_updated')}
    else
      render json: {errors:@link.errors}, status: 400
    end
  end

  def validate_custom_link
    @link= CustomLink.find(params[:id]) 
    params[:link].each do |key, value|
      @link[key]=value
    end
    if @link.valid?
      head :ok
    else
      render json: {errors:@link.errors.full_messages}, status: :unprocessable_entity
    end
    
  end

  def link_copy
    id = params[:id] || params[:link_id]
    old_link = CustomLink.find(id)
    new_group = Group.find(params[:module_id])
    copy_link= old_link.dup
    copy_link.course_id = params[:course_id]
    copy_link.group_id  = params[:module_id]
    copy_link.position = new_group.get_items.size+1
    copy_link.save(:validate => false)
    
    render json:{link: copy_link, :notice => [I18n.t("controller_msg.link_successfully_updated")]} 
  end

  def destroy
    if @custom_link.destroy

      render json: {:notice => [I18n.t("controller_msg.link_successfully_deleted")]}
    else 
      render json: {errors:@link.errors.full_messages}, status: :unprocessable_entity  
    end
  end

  # def link_copy
  # end
  
private

  def custom_link_params
    params.require(:link).permit(:course_id, :group_id, :name, :url, :position, :course_position)
  end
end
