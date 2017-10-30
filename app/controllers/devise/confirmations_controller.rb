class Devise::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def create
        self.resource = resource_class.send_confirmation_instructions(resource_params)
        puts "RESOURCE IS!!"
        puts resource
        if successfully_sent?(resource)
        set_flash_message(:notice, :send_instructions)
        respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
        else
        respond_with(resource)
        end
    end
end

