class SharedItemsController < ApplicationController
	
	load_and_authorize_resource
	
	# def index
	# end

	# def create
	# end

	# def update
	# end

	# def destroy
	# end

	# def show
	# end

	# def show_shared
	# end

	# def update_shared_data
	# end

	# def accept_shared
	# end

	# def reject_shared
	# end
	private
		def group_params
			params.require(:shared_item).permit(:data, :shared_by_id, :shared_with_id, :accept)
		end
end