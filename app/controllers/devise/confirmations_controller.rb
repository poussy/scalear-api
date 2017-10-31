class Devise::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def create
        p params
        self.resource = resource_class.send_confirmation_instructions(params)
       
        if !successfully_sent?(resource)
            resource.send_confirmation_instructions
        else
            respond_with(resource)
        end
    end
end

