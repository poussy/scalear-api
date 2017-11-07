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
    p params[:link]
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

  def destroy
    if @custom_link.destroy

      render json: {:notice => [I18n.t("controller_msg.link_successfully_deleted")]}
    else 
      render json: {errors:@link.errors.full_messages}, status: :unprocessable_entity  
    end
  end


private

  def custom_link_params
    params.require(:link).permit(:course_id, :group_id, :name, :url, :position, :course_position)
  end
end
