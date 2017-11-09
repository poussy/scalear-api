class LtiResource < ApplicationRecord
	validates :resource_context_id, :sl_type_name_type_id, :presence => true  #:percent
end