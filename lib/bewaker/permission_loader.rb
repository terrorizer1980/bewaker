module Bewaker
  class PermissionLoader
    class << self
      def allowed_field?(object, field)
        return true

        # Opa::DataMasker.protected_fields.any? do |role, role_fields|
        #   object.try("is_#{role}") &&
        #     role_fields.include?(field.to_s)
        # end

        input = {
          subject: {
            id: 1,
            is_anc_triager: false,
          },
        }

        resource = if object.class.name == "HacktivityItems::Disclosed"
          "hacktivity_items"
        else
          # Current implementation only supports thse two types.
          "reports"
        end

        # normal_evaluation_check(resource, field, input)
        disclosed_attributes, functions = partial_evaluation_check(resource, object, field, input)

        cache[request][object.class] = disclosed_attributes, functions

        object.team.state == 5

        object.team

        functions
      end

      def normal_evaluation_check(resource, field, input)
        resource_path = "/filtering/#{resource}/disclosed"

        # TODO: send object to OPA.
        opa_result = Opa::Client.normal_evaluation(input, resource_path)
        disclosed_attributes = opa_result["result"]

        return false unless disclosed_attributes

        disclosed_attributes.include?(field.to_s)
      end

      def partial_evaluation_check(resource, object, field, input)
        query = "data.filtering.#{resource}.disclosed_attributes"
        opa_result = Opa::Client.partial_evaluation(
          input,
          query,
          ["data.reports", "data.hacktivity_items"]
        )

        return false unless opa_result["result"]

        opa_rules = opa_result["result"]["support"][0]["rules"]

        # TODO: For each OPA partial evaluation rule, verify the condition
        # on "object" within the Ruby runtime. (Would that be performant?)
        # Of course taking into account that the disclosed_attributes can be
        # cached for the current session and the object, so we do not have to
        # calculate the attributes for each field.

        disclosed_attributes = []
        opa_rules.each do |rule|
          next unless rule["head"]["name"] == "disclosed_attributes"
          attributes = rule["head"]["value"]
          rule["body"].each do |condition|
            Opa::RubyVisitor.accept(condition)
          end
          # If all conditions of the rule satisfy, add "attributes" to "disclosed_attributes"
        end

        # If "field" is in "disclosed_attributes", the user is allowed to see the field.s
        disclosed_attributes.include?(field.to_s)
      end
    end
  end
end
