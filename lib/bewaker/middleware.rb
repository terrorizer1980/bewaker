module Bewaker
  class Middleware
    def self.secure(node_name, enhanced_arel, context)
      if node_name == ::Opa::MODEL_REPORTS
        self.secure_reports enhanced_arel, context
      elsif node_name == Opa::MODEL_HACKTIVITY_ITEMS
        self.secure_hacktivity_items enhanced_arel, context
      end
    end

    def self.get_base_input(context)
      # {
      #   subject: {
      #     id: context[:current_user].id,
      #     is_anc_triager: context[:current_user].anc_triager,
      #   },
      # }
      {
        subject: {
          id: 1,
          is_anc_triager: false,
        },
      }
    end

    def self.secure_arel(input, query, unknowns, enhanced_arel)
      opa_result = Opa::Client.partial_evaluation(input, query, unknowns)
      convert_sql opa_result, enhanced_arel, input
    end

    def self.secure_reports(enhanced_arel, context)
      input = get_base_input context
      query = "data.filtering.reports.allow == true"
      unknowns = [
        "data.reports",
        "data.role",
      ]
      secure_arel input, query, unknowns, enhanced_arel
    end

    def self.secure_hacktivity_items(enhanced_arel, context)
      input = get_base_input context
      query = "data.filtering.hacktivity_items.allow == true"
      unknowns = [
        "data.hacktivity_items",
        "data.role"
      ]
      secure_arel input, query, unknowns, enhanced_arel
    end

    def self.convert_sql(opa_result, enhanced_arel, input)
      if opa_result.fetch("result").empty?
        fail Pavlov::AccessDenied, "Unauthorized resource"
      end

      condition, projection = create_authorized_condition opa_result
      merge(enhanced_arel, condition, projection, input)
    end

    def self.create_authorized_condition(opa_result)
      ::Opa::SQLVisitor.new.accept(opa_result)
    end

    def self.merge(enhanced_arel, condition, projection, input)
      model = Opa::SQLVisitor.table_name_to_model(enhanced_arel.object.name)
      # TODO: the input for requester_id might break if it's NULL
      requester_id = Arel::Nodes::As.new(input.fetch(:subject).fetch(:id), Arel.sql('_requester_id'))
      wrapper_from = model.unscoped.select(model.arel_table[Arel.star], requester_id).where(condition).arel.as(enhanced_arel.object.name)

      # if projection
      #   new_projections = enhanced_arel[0].ast.cores[0].projections.object + projection
      #   enhanced_arel[0].ast.cores[0].projections.replace(new_projections)
      # end

      enhanced_arel.replace(wrapper_from)

      enhanced_arel
    end
  end
end


# SELECT COUNT(*) FROM reports
# SELECT COUNT(*) FROM (SELECT *, requester_id FROM reports) AS reports

# SELECT COUNT(*), requester_id FROM reports