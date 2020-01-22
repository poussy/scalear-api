module CcUtils
    def cc_course(course)
        transformed_course = CanvasCc::CanvasCC::Models::Course.new
        transformed_course.title = course.name
        transformed_course.grading_standards = []
        transformed_course.identifier = course.id.to_s
        transformed_course.grading_standards=[]
        course.groups.each do |group|
            transformed_group = cc_groups(group)
            transformed_course.canvas_modules << transformed_group
        end 
        dir = Dir.mktmpdir
        carttridge = CanvasCc::CanvasCC::CartridgeCreator.new(transformed_course)
        path = carttridge.create(dir)
        return path   
    end

    def cc_groups(group)
        transformed_group = CanvasCc::CanvasCC::Models::CanvasModule.new
        transformed_group.title = group.name
        transformed_group.identifier = group.id

        group.lectures.each do |lecture|
            transformed_lecture = cc_items(lecture)
            transformed_group.module_items << transformed_lecture
        end    
        return transformed_group
    end 

    def cc_items(lecture)
        transformed_lecture = CanvasCc::CanvasCC::Models::ModuleItem.new
        transformed_lecture.identifier = lecture.id
        transformed_lecture.title = lecture.name
        transformed_lecture.url = lecture.url
        transformed_lecture.content_type = "ExternalUrl"
        return transformed_lecture
    end         
end