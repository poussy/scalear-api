class YtDataApiReqLogsController < ApplicationController 
    def show
    end    
    def register_YT_api_request_angular
        apiReqRecord = YtDataApiReqLog.create(cause:params['cause'], lecture_id: params['lecture_id'],user_id: params['user_id'])
        if apiReqRecord.save
            render :json => {:success => true, :notice => [I18n.t("lectures.request_api_recorded_successfully")]}
        else 
            render :json => {:failure => true, :notice => [I18n.t("lectures.request_api_is_not_recorded_successfully")]}
        end
    end

end    