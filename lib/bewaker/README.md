# OPA Prototype

## TODO
- [x] Choose different use case -> hacktivity_items query
- [x] Improve current code
- [x] Add support to OPA visitor and middleware for hacktivity_items
- [x] Add authorization to inline queries
- [ ] Column protection
- [ ] Filter protection -> Filtering by title returns reports by that title = not allowed when you can't see the attribute.
- [ ] More context to OPA (role not as unknown?)
- [ ] Check if all conditions are present
- [ ] Seed hacktivity items for better benchmark
- [ ] Before / after benchmark local machine
- [ ] Evaluate policies without OPA server
- [ ] Fix feature flags
- [ ] Before / after benchmark production
- [ ] Figure out how to use functions / modules between Rego 
  files to prevent duplication.

## Query
**Query**
```
query HacktivityPageQuery(
  $querystring: String
  $orderBy: HacktivityItemOrderInput
  $where: FiltersHacktivityItemFilterInput
  $cursor: String
) {
  hacktivity_items(
    after: $cursor
    query: $querystring
    order_by: $orderBy
    where: $where
    first: 1
  ) {
    total_count
    edges {
        node {
            ... on Disclosed {
                id
                total_awarded_amount
            }
            __typename
        }
    }
  }
}
```

**Variables**
```
{
    "maxShownVoters": 10,
    "orderBy": {"field": "popular", "direction": "DESC"},
    "querystring": "",
    "secureOrderBy": null,
    "where": {"report": {"disclosed_at": {"_is_null": false}}}
}
```

## Design

Any design explanations can be listed in this section.

### High Level

* Query is intercepted
* For each model, a request is made to the OPA partial evaluation API, the
  result contains the conditions that need to be evaluated, and this is converted
  to an SQL condition which is added to the (inner) query in the WHERE clause.

**Example**
```
body {
  input: {
    subject: {
      id: 1,
      is_anc_triager: false,
  },
  query: "data.filtering.hacktivity_items.allow == true"
  unknowns: [
    "data.hacktivity_items",
    "data.role"
  ]
}
```

* For each model, a request is made to the OPA normal evaluation API, the result
  contains the attributes that the requester is allowed to see, the GraphQL .authorized?
  field method checks for each field whether it is included in the OPA response.

**Example**

Url
```
http://localhost:8181/v1/data/filtering/#{resource}/disclosed
```

Body
```
body {
  input = {
    subject: {
      id: 1,
      is_anc_triager: false,
    },
  }
}
```

Response
```
{
  "decision_id": "6a7f76e3-8650-4006-b535-4c56e1e0c1fd",
  "result": [
    "id",
    "reporter_id",
    "total_awarded_amount"
  ]
}
```


## Useful

**Generated SQL after OPA row level access**
```
SELECT
    hacktivity_items.id
FROM (
    SELECT "hacktivity_items".* FROM (
        SELECT "hacktivity_items".* FROM "hacktivity_items" WHERE EXISTS (
            SELECT 1 FROM "reports" WHERE "hacktivity_items"."report_id" = "reports"."id" AND "reports"."hacker_published" = TRUE
        ) AND EXISTS (
            SELECT 1 FROM "reports" WHERE "hacktivity_items"."report_id" = "reports"."id" AND "reports"."disclosed_at" IS NOT NULL
        ) OR EXISTS (
            SELECT 1 FROM "teams" WHERE "hacktivity_items"."team_id" = "teams"."id" AND "teams"."state" = 5
        ) OR EXISTS (
            SELECT 1 FROM "teams" WHERE "hacktivity_items"."team_id" = "teams"."id" AND "teams"."state" = 4
        ) AND EXISTS (
            SELECT 1 FROM "teams" INNER JOIN "team_members" ON "team_members"."team_id" = "teams"."id" INNER JOIN "users" ON "users"."id" = "team_members"."user_id" WHERE "hacktivity_items"."team_id" = "teams"."id" AND "users"."id" = 1
        ) OR EXISTS (
            SELECT 1 FROM "teams" WHERE "hacktivity_items"."team_id" = "teams"."id" AND "teams"."state" = 4
        ) AND EXISTS (
            SELECT 1 FROM "teams" INNER JOIN "whitelisted_reporters" ON "whitelisted_reporters"."team_id" = "teams"."id" INNER JOIN "users" ON "users"."id" = "whitelisted_reporters"."user_id" WHERE "hacktivity_items"."team_id" = "teams"."id" AND "users"."id" = 1
        )
    ) AS "hacktivity_items" WHERE EXISTS (
        SELECT 1 FROM (
            SELECT "reports".* FROM "reports" WHERE TRUE = TRUE AND "reports"."reporter_id" = 1 OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "teams" INNER JOIN "team_members" ON "team_members"."team_id" = "teams"."id" INNER JOIN "users" ON "users"."id" = "team_members"."user_id" WHERE "reports"."team_id" = "teams"."id" AND "users"."id" = 1
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_retests" INNER JOIN "report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" INNER JOIN "users" ON "users"."id" = "report_retest_users"."user_id" WHERE "reports"."id" = "report_retests"."report_id" AND "users"."id" = 1
            ) AND EXISTS (
                SELECT 1 FROM "report_retests" WHERE "reports"."id" = "report_retests"."report_id" AND "report_retests"."state" = 'approved'
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_retests" INNER JOIN "report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" INNER JOIN "users" ON "users"."id" = "report_retest_users"."user_id" WHERE "reports"."id" = "report_retests"."report_id" AND "users"."id" = 1
            ) AND EXISTS (
                SELECT 1 FROM "report_retests" WHERE "reports"."id" = "report_retests"."report_id" AND "report_retests"."state" = 'assigned'
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_retests" INNER JOIN "report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" INNER JOIN "users" ON "users"."id" = "report_retest_users"."user_id" WHERE "reports"."id" = "report_retests"."report_id" AND "users"."id" = 1
            ) AND EXISTS (
                SELECT 1 FROM "report_retests" WHERE "reports"."id" = "report_retests"."report_id" AND "report_retests"."state" = 'claimed'
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_retests" INNER JOIN "report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" INNER JOIN "users" ON "users"."id" = "report_retest_users"."user_id" WHERE "reports"."id" = "report_retests"."report_id" AND "users"."id" = 1
            ) AND EXISTS (
                SELECT 1 FROM "report_retests" WHERE "reports"."id" = "report_retests"."report_id" AND "report_retests"."state" = 'needs_approval'
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_retests" INNER JOIN "report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" INNER JOIN "users" ON "users"."id" = "report_retest_users"."user_id" WHERE "reports"."id" = "report_retests"."report_id" AND "users"."id" = 1
            ) AND EXISTS (
                SELECT 1 FROM "report_retests" WHERE "reports"."id" = "report_retests"."report_id" AND "report_retests"."state" = 'rejected'
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "report_collaborators" WHERE "reports"."id" = "report_collaborators"."report_id" AND "report_collaborators"."user_id" = 1
            ) OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "teams" WHERE "reports"."team_id" = "teams"."id" AND "teams"."state" = 5
            ) AND "reports"."disclosed_at" IS NOT NULL AND "reports"."public_view" = 'full' OR TRUE = TRUE AND EXISTS (
                SELECT 1 FROM "teams" WHERE "reports"."team_id" = "teams"."id" AND "teams"."state" = 5
            ) AND "reports"."disclosed_at" IS NOT NULL AND "reports"."public_view" = 'no-content'
        ) AS "reports" WHERE "reports"."id" = "hacktivity_items"."report_id" AND "reports"."disclosed_at" IS NOT NULL
    )
) AS "hacktivity_items" ORDER BY "id", "id" ASC LIMIT 100;
```

**Manually crafted SQL for column level access**
```
SELECT 
    hacktivity_items.id AS hacktivity_item_id,
    reporter.id AS reporter_id,
    reports.title AS report_title,

    (1 = 3) as my_boolean,

    (user_display_options.show_bounty_amounts = TRUE 
    OR user_display_options.show_bounty_amounts = null
    OR reporter.id = 2
    OR team_members.user_id = 1
    ) AS user_has_bounty_disclosed,

    (   (
        teams.state = 5 
        AND reports.disclosed_at != null
        )
    OR (
        whitelisted_reporters.user_id = 2
        AND reports.disclosed_at != null
        AND teams.state = 4
        AND teams.allows_private_disclosure = TRUE
        AND reports.public_view = 'full'
        )
    OR (
        whitelisted_reporters.user_id = 2
        AND reports.disclosed_at != null
        AND teams.state = 4
        AND teams.allows_private_disclosure = TRUE
        AND reports.public_view = 'no-content'
        )
    OR team_members.user_id = 2
    ) AS user_has_bounty_disclosed

FROM hacktivity_items
INNER JOIN reports ON reports.id = hacktivity_items.report_id
INNER JOIN users AS reporter ON reporter.id = reports.reporter_id
INNER JOIN teams ON teams.id = reports.team_id
LEFT JOIN team_members ON team_members.team_id = reports.team_id
LEFT JOIN user_display_options ON user_display_options.user_id = reporter.id
LEFT JOIN whitelisted_reporters ON whitelisted_reporters.team_id = teams.id
WHERE hacktivity_items.id IN 
    (15, 16, 21, 43, 44, 47, 48, 50, 53, 54, 56, 60, 62, 
    63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75);
```

But the above results is SQL fanouts, therefore it needs to be refactored in the following form:

```
SELECT 
EXISTS(SELECT 1 FROM reports WHERE hacktivity_items.report_id == reports.id INNER JOIN users ON users.id = reports.reporter_id INNER JOIN user_display_options ON user_display_options.user_id = users.id WHERE user_display_options.show_bounty_amounts = TRUE) as user_has_bounty_disclosed
FROM
  hacktivity_items
LIMIT 100
```

Each rule needs to be an inner query in an exists clause.
