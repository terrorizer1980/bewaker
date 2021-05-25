class ReportPolicy
  match_first_policy

  # triggers when team_id is present in the query
  # is used to differentiate between different perspectives of the data
  # query reports from the team member perspective
  # query reports from the hacker perspective
  # query reports from the public perspective
  policy do
    action 'read'
    target 'reports'
    params [:team_id]

    rule do
      is_team_member | is_anc_triager
    end
  end

  # triggers when reporter_id is present in the query
  policy do
    action 'read'
    target 'reports'
    params [:reporter_id]

    rule do
      is_reporter
    end
  end

  # differentiate betwee index/show operation? How do we do that? By indicating the id needs to be present?
  policy do
    action 'read'
    target 'reports'
    params [:id]
  end
end

# roles a user can have for a report:

# participants
# (has_role(REPORTER) |
# has_role(TEAM_MEMBER) |
# has_role(EXTERNAL_USER) |
# has_role(ANC_TRIAGER) |
# has_role(PARTICIPATING_RETESTER) |
# has_role(REPORT_COLLABORATOR))

# other viewers
# has_role(SOMEONE_VISITING_A_PUBLIC_REPORT) |
# has_role(SOMEONE_VISITING_A_PUBLIC_LIMITED_REPORT) |
# has_role(SOMEONE_VISITING_A_REPORT_PRIVATELY_DISCLOSED_TO_THEM) |
# has_role(SOMEONE_VISITING_A_LIMITED_REPORT_PRIVATELY_DISCLOSED) |
# has_feature(HACKER_PUBLISHED) |
# has_role(PARTICIP_RETEST_DEPR_WITH_INV) |
# has_role(PARTICIP_RETEST_DEPR_WITHOUT_INV)

# which roles actually have a use case for querying/searching/listing reports? 