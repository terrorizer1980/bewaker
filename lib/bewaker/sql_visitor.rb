module Bewaker
	class SQLVisitor
		attr_reader :object
		attr_reader :subroles
		attr_reader :current_subrole

		# TODO: this 100% will not work for all cases
		def self.table_name_to_model(str)
			str.singularize.camelize.constantize
		end

		def accept(opa_result)
			@object = opa_result
			@subroles = {}
			@current_subrole = nil

			visit(object, :result)
		end

		private

		def visit(data, current_attribute = :type)
			if data.is_a? Array
				return data.map { |attr| visit(attr, current_attribute) }
			end

			dispatch_method = "visit_#{current_attribute.to_s}"

			unless self.class.private_method_defined? dispatch_method
				raise "Not implemented: #{current_attribute}"
			end

			send(dispatch_method, data)
		end

		def visit_type(data)
			type = data["type"]
			dispatch_method = "visit_#{type}"
			send(dispatch_method, data)
		end

		def visit_result(data)
			visit(data["result"], :queries)
		end

		def visit_queries(data)
			data = data["queries"]

			if data.nil?
				return Arel::Nodes::Equality.new(Arel.sql("TRUE"), Arel.sql("FALSE"))
			end

			output = visit(data, :terms)
			wheres = combine_conditions_to_or(output)
			# role_projections = Opa::DataMasker.new(@subroles).role_projections

			[wheres, nil]
		end

		def visit_terms(data)
			data = data["terms"]

			operator, left_hand_side, right_hand_side = data
			operator_class = visit(operator["value"], :operator).first

			# TODO: we should think of a better strategy than this
			left_hand_side_value = visit(left_hand_side, :type)
			right_hand_side_value = visit(right_hand_side, :type)

			# Ensure left hand side is the attribute we're checking
			# and right hand side is the value.
			if left_hand_side_value.is_a?(Array) && right_hand_side_value.is_a?(Array)
				raise "Not sure what to do here 😅"
			elsif right_hand_side_value.is_a?(Array)
				tmp = left_hand_side_value
				left_hand_side_value = right_hand_side_value
				right_hand_side_value = tmp
			end

			# [reports, team, team_members, users, id]
			path = left_hand_side_value.compact

			# reports
			table_name = path.first

			# role: reporter/team_member/external_user/...
			if table_name == "role"
				@current_subrole = right_hand_side_value
				@subroles[@current_subrole] ||= [] if @current_subrole

				return Arel::Nodes::Equality.new(Arel.sql("TRUE"), Arel.sql("TRUE"))
			end

			model = self.class.table_name_to_model table_name

			result = if column?(model, path.second)
								 model.arel_table[path.second].public_send(operator_class, right_hand_side_value)
							 else
								 association_model = klass_from_association(model, path.second) # Team
								 constraint = correlated_constraint(model, path.second)

								 inner_query = association_model.unscoped.select(1).where(constraint)
								 inner_query = build_condition(inner_query, path[1..], right_hand_side_value, operator_class)
								 inner_query.arel.exists
							 end


			@subroles[@current_subrole] << result if @current_subrole

			result
		end

		def visit_operator(data)
			case data["value"]
			when "eq"
				'eq'
			when "neq"
				'not_eq'
			else
				raise "Not implemented operator: #{data["value"]}"
			end
		end

		def visit_null(data)
			nil
		end

		def visit_ref(data)
			visit(data.fetch("value"))
		end

		def visit_var(data)
			return
			data["value"]
		end

		def visit_number(data)
			data["value"]
		end

		def visit_string(data)
			data["value"]
		end

		def visit_boolean(data)
			data["value"]
		end

		def visit_prepare_stmt(name:, query:, argtypes: nil)
			Arel::Nodes::Prepare.new name, argtypes && visit(argtypes), visit(query)
		end

		def build_condition(model, associations, conditional_variable, operator_class)
			# Input: [reports, team, team_members, users, id]
			#
			# Output: Report.joins(:team).merge(Team.joins(:team_members).merge(TeamMember.joins(:user)))
			#
			# Generated SQL:
			# SELECT * from reports
			# where exists(
			#   select 1 from teams
			#     inner join team_members on teams.id = team_members.team_id
			#     inner join users on users.id = team_members.user_id
			#   where users.id = 1 and teams.id = reports.team_id
			# )
			#
			#
			association = associations[1].to_sym

			if model.column_names.include?(association.to_s)
				model.where(
					model.arel_table[association].public_send(operator_class, conditional_variable),
				)
			else
				association_model = klass_from_association(model, association) # Team
				builded = build_condition(association_model, associations[1..], conditional_variable, operator_class)
				model.joins(association).merge(builded)
			end
		end

		def klass_from_association(model, association)
			if model.reflections[association.to_s].nil?
				raise ArgumentError, "missing association name `#{association}` for model #{model}. Possible associations are: #{model.reflections.keys.join(", ")}"
			end

			model.reflections[association.to_s].klass
		end

		def correlated_constraint(model, association)
			association_model = klass_from_association(model, association)
			reflection = model.reflections[association.to_s]

			if reflection.nil?
				raise ArgumentError, "missing association name `#{association}` for model #{model}. Possible associations are: #{model.reflections.keys.join(", ")}"
			end

			case reflection
			when ActiveRecord::Reflection::BelongsToReflection
				# TODO: calling primary key here calls the middleware two times breaking execution
				# current hack is to hardcode the primary key on the models.
				model
					.arel_table[reflection.foreign_key]
					.eq(association_model.arel_table[association_model.primary_key])
			when ActiveRecord::Reflection::HasManyReflection
				model
					.arel_table[model.primary_key]
					.eq(association_model.arel_table[reflection.foreign_key])
			when ActiveRecord::Reflection::HasAndBelongsToManyReflection
				# table_name = table_name_from_join_table(reflection)
				# primary_key, foreign_key_1, foreign_key_2 = column_names_from_join_table(reflection)
				reflection_model = join_table_name_to_model(table_name_from_join_table(reflection))

				# "reports"."id" = "reports_users"."report_id"
				first_join = model
					.arel_table[model.primary_key]
					.eq(reflection_model.arel_table[reflection.foreign_key]),
				# "users"."id" = "reports_users"."user_id"
				second_join = association_model
					.arel_table[association_model.primary_key]
					.eq(reflection_model.arel_table[reflection.association_foreign_key])

				# merge the joins, return `INNER JOIN "reports_users" ON "reports_users"."report_id" = "reports"."id" INNER JOIN "users" ON "users"."id" = "reports_users"."user_id"``
				result = model
					.arel_table
					.join(reflection_model.arel_table)
					.on(first_join)
					.join(association_model.arel_table)
					.on(second_join)
			when ActiveRecord::Reflection::ThroughReflection
				# model: Team
				# association_model: User
				# association: whitelisted_reporters
				# reflection: ThroughReflection, delegate HasManyReflection
				model_table = model.arel_table[reflection.foreign_key]
				association_table = association_model.arel_table[model.primary_key]
				model_table.eq(association_table)
			else
				raise ArgumentError, "unknown reflection `#{reflection.class}` for model `#{model}` and association `#{association}`"
			end
		end

		def table_name_from_join_table(reflection)
			reflection.options[:join_table].to_s
		end

		def column_names_from_join_table(reflection)
			reflection.options[:join_table].to_s.classify.pluralize.constantize.column_names
		end

		def join_table_name_to_model(str)
			str.classify.pluralize.constantize
		end

		def combine_conditions_to_or(conditions)
			conditions.map do |or_branch_members|
				or_branch_members.inject do |memo, condition|
					Arel::Nodes::And.new([memo, condition])
				end
			end.inject do |memo, condition|
				Arel::Nodes::Or.new(memo, condition)
			end
		end

		def column?(model, association)
			model.column_names.include?(association.to_s)
		end
	end
end
