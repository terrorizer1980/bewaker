SELECT "hacktivity_items".*, "hacktivity_items".* FROM (
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
) AS "hacktivity_items" ORDER BY "id", "id" ASC LIMIT $1
