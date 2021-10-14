module Bewaker
  class DataMasker
    attr_reader :resource_subroles

    def initialize(subroles = [])
      @resource_subroles = subroles
    end

    def role_projections
      # Opa::DataMasker.role_subrole_mapping.map do |role, subroles|
      #   role_condition = subroles.inject do |memo, subrole|
      #     and_branch_members = @resource_subroles[subrole]
      #     next if and_branch_members.nil?
      #
      #     subrole_condition = and_branch_members.inject do |inner_memo, condition|
      #       Arel::Nodes::And.new([inner_memo, condition])
      #     end
      #     Arel::Nodes::Or.new(memo, subrole_condition)
      #   end
      #
      #   Arel::Nodes::Grouping.new(role_condition).as("is_#{role}")
      # end
      #
      role_conditions = {}

      @resource_subroles.each do |subrole, inner_conditions|
        role = role_for_subrole(subrole)
        role_conditions[role] ||= []

        condition = inner_conditions.inject do |inner_memo, condition|
          Arel::Nodes::And.new([inner_memo, condition])
        end
        role_conditions[role] += [condition]
      end

      role_conditions.map do |role, conditions|
        result_condition = conditions.inject do |memo, condition|
          Arel::Nodes::Or.new(memo, condition)
        end

        Arel::Nodes::Grouping.new(result_condition).as("is_#{role}")
      end
    end

    def role_for_subrole(subrole)
      Opa::DataMasker.role_subrole_mapping.find do |_role, subroles|
        subroles.include? subrole
      end&.first
    end

    class << self
      def protected_fields
        @protected_fields ||= roles_meta("protected_fields")
      end

      def role_subrole_mapping
        @role_subrole_mapping ||= roles_meta("role_subrole_mapping")
      end

      private

      def roles_meta(type)
        Rails.cache.fetch(type) || download_roles_meta.fetch(type)
      end

      def download_roles_meta
        response = HTTParty.post(
          "http://localhost:8181/v1/data",
          headers: {
            "Content-Type" => "application/json",
          },
        )&.fetch("result")
        role_subrole_mapping = response&.fetch("role_subrole_mapping", nil)
        protected_fields = response&.fetch("protected_fields", nil)

        fail "Failed to fetch role data from OPA" if role_subrole_mapping.nil? || protected_fields.nil?

        Rails.cache.write_multi(
          role_subrole_mapping: role_subrole_mapping,
          protected_fields: protected_fields,
        )

        response
      end
    end
  end
end
