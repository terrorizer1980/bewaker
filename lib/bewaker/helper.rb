module Bewaker
  MODEL_REPORTS = "reports"
  MODEL_HACKTIVITY_ITEMS = "hacktivity_items"
  TYPE_REPORT = "ReportType"
  TYPE_HACKTIVITY_ITEM = "HacktivityItemType"
  TYPE_HACKTIVITY_ITEM_DISCLOSED = "HacktivityItems::DisclosedType"

  class Helper
    SUPPORTED_MODELS = [
      Opa::MODEL_HACKTIVITY_ITEMS
    ]

    SUPPORTED_TYPES =[
      Opa::TYPE_HACKTIVITY_ITEM,
      TYPE_HACKTIVITY_ITEM_DISCLOSED
    ]

    def self.opa_enabled?(requester, entity)
      feature_enabled?(requester) && supported?(entity)
    end

    def self.feature_enabled?(requester)
      true
      # Feature.enabled_key_for_user(Feature::BEWAKER, requester).exists?
    end

    def self.supported?(entity)
      return (model_supported?(entity) || type_supported?(entity))
    end

    def self.model_supported?(model_name)
      return SUPPORTED_MODELS.include? model_name
    end

    def self.type_supported?(type_name)
      return SUPPORTED_TYPES.include? type_name.to_s
    end
  end
end
