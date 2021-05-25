# subject (current_user)
# object/resource (reports, teams)
# action (read, write) OR (transfer,amount=500)
# environment

# data
# input
# input.method
# input.path
# input.subject
# input.subject

class ReportPolicy
    policy read_reports do
      target action_id: :read, object: Report
  
      rule "is_reporter" do
        permit
        resource.reporter == subject
      end
  
      rule "is_team_member" do
        permit
        resource.team.team_members.include?(subject)
      end
  
      rule "is_pentester" do
        resource.feature_enabled & resource.pentest.pensters.include?(subject)
      end
  
      rule "fail_safe" do
        deny
        on deny do
          advice notify do
            "Your request did match the policy"
          end
        end
      end
    end
  end
  
  class TeamPolicy
      attribute(:is_team_member) do |input|
         joins(team_members: :users).where(users: { id: input.subject })
      end
  
      policy(:read) do
        is_team_member | is_reporter
      end
  
      policy(:write) do
        is_team_member
      end
  
      policy(:update_title) do
      end
  end
  
  class ReportPolicy
      copy_attributes(TeamPolicy)
  
      attribute(:is_banned) do |input|
        User.where(id: input.subject)
      end
  
      attribute(:is_reporter) do
        data.report.reporter == data.current_user
      end
  
      policy(:read) do
          rule("deny banned users") do
              clause is_banned
              deny
          end
  
          rule("reporters") do |input|
            clause Report.where(reporter: input.subject)
            permit
          end
  
          rule("team_members") do |input|
            clause Report.joins(team: { team_members: :users }).where(users: { id: input.subject })
            permit
          end
      end
  
      attribute(:feature_enabled) do
          if input.team_id
            Rails.cache do
              Feature.where(team_id: team_id, key: 'feature').exists?
            end
          else
            data.features.
          end
      end
  
      policy do
  
      end
  end
  
  # https://en.wikipedia.org/wiki/ALFA_(XACML)
  # https://www.axiomatics.com/blog/intro-to-attribute-based-access-control-abac/
  # https://play.openpolicyagent.org/
  
  # from https://github.com/ifad/eaco
  user.can?(:read, document)
  report.allows?(:read, user)
 
  


