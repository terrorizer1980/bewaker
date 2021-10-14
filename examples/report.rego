package filtering.reports


default allow = false

# A user can view a report that’s private disclosed in a team he/she’s a whitelisted reporter of.
# A user can view a report that’s hacker published.

allow {
	is_reporter
}

allow {
	is_team_member
}

allow {
	is_anc_triager
}

#allow {
# 	is_external_user
#}

allow {
	is_retesting_user
}

allow {
	is_report_collaborator
}

allow {
	is_report_public_disclosed
}

allow {
	is_report_partial_disclosed
}

# A user can query reports he/she reported.
is_reporter {
	data.role == "reporter"
	data.reports[_].reporter_id == input.subject.id
}

# A user can query reports that are submitted to a team he/she’s a member of.
is_team_member {
	data.role == "team_member"
	data.reports[_].team.team_members[_].user[_].id == input.subject.id
}

# An anc triager can query reports in one of the pre-submission review states.**
is_anc_triager {
	data.role == "anc_triager"
	input.subject.is_anc_triager
	data.reports[_].substate = "pre-submission"
}

# A user can view a report that he/she is an external user of.
# is_external_user {
# 	data.reports[_].external_users[_].user_id == input.subject.id
# }

# A user can view a report that he/she’s retesting.

is_retesting_user {
	data.role == "retesting_user"
	state_set := {"approved", "assigned", "claimed", "needs_approval", "rejected"}
	data.reports[_].report_retests[_].report_retest_users[_].user[_].id == input.subject.id
	state_set[data.reports[_].report_retests[_].state]
}

# A user can view a report that he/she’s collaborating on.
is_report_collaborator {
	data.role == "report_collaborator"
	data.reports[_].report_collaborators[_].user_id == input.subject.id
}

# A user can view a report that is public disclosed.
# A user can view a report that is partial disclosed.
is_report_public {
	data.reports[_].team.state == 5
	data.reports[_].disclosed_at != null
}

is_report_public_disclosed {
	data.role == "report_public_disclosed"
	is_report_public
	data.reports[_].public_view = "full"
}

is_report_partial_disclosed {
	data.role == "report_partial_disclosed"
	is_report_public
	data.reports[_].public_view = "no-content"
}

disclose_partial_disclosure := [
    "id",
    "_id",
    "team_id",
    "substate",
    "reporter_id",
    "created_at",
    "disclosed_at",
    "title",
    "ineligible_for_bounty",
    "hacker_published",
]

disclose_viewer := [
    "vulnerability_information"
]

disclose_participant := [
    "cloned_from_id",
    "hacker_triage_rateable_state_for_current_user?",
    "available_hacker_triage_rating_options",
    "state",
    "bounty_amount",
    "cve_ids",
    "public?",
    "draft?",
    "severity_rating",
    "eligible_for_hacktivity?",
    "comments_closed",
    "external_bug?",
    "link_sharing_enabled?",
    "allow_singular_disclosure_at",
    "allow_singular_disclosure_after",
    "singular_disclosure_allowed",
    "bug_reporter_agreed_on_going_public_at",
    "team_member_agreed_on_going_public_at",
    "triaged_at",
    "closed_at",
    "attachments",
    "bounties",
    "bounty_awarded_at",
    "first_program_activity_at",
    "latest_public_activity_at",
    "latest_public_activity_of_reporter_at",
    "latest_public_activity_of_team_at",
    "swag",
    "swag_awarded_at",
    "structured_scope_id",
    "weakness_idv",
    "pentest_id",
    "latest_report_state_change_at",
    "i_can_post_hacker_triage_rating?",
    "visibility"
]

# TODO disclose_team_member

_disclosed_attributes[0] = disclose_partial_disclosure {
    is_report_partial_disclosed
}

_disclosed_attributes[1] = disclose_viewer {
    is_report_public_disclosed
}

# TODO: How to make these an OR?
_disclosed_attributes[2] = disclose_participant {
    is_reporter
    is_anc_triager
    is_retesting_user
    is_report_collaborator
}

disclosed := {x | x = _disclosed_attributes[_][_]}
