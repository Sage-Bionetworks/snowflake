USE ROLE USERADMIN;

// Platform
CREATE USER IF NOT EXISTS "diep.thach@sagebase.org";
CREATE USER IF NOT EXISTS "x.schildwachter@sagebase.org";
CREATE USER IF NOT EXISTS "kevin.boske@sagebase.org";
CREATE USER IF NOT EXISTS "john.hill@sagebase.org";
CREATE USER IF NOT EXISTS "bruce.hoff@sagebase.org";
CREATE USER IF NOT EXISTS "marco.marasca@sagebase.org";
CREATE USER IF NOT EXISTS "sandhra.sokhal@sagebase.org";
CREATE USER IF NOT EXISTS "adam.hindman@sagebase.org";
CREATE USER IF NOT EXISTS "jay.hodgson@sagebase.org";
CREATE USER IF NOT EXISTS "nick.grosenbacher@sagebase.org";
CREATE USER IF NOT EXISTS "hallie.swan@sagebase.org";
CREATE USER IF NOT EXISTS "khai.do@sagebase.org";
-- This user is managed by Jumpcloud, thus they exist outside
-- the usual user creation process.
-- CREATE USER IF NOT EXISTS "joni.harker@sagebase.org";

// Cancer Bio
CREATE USER IF NOT EXISTS "adam.taylor@sagebase.org";
CREATE USER IF NOT EXISTS "chelsea.nayan@sagebase.org";
CREATE USER IF NOT EXISTS "xindi.guo@sagebase.org";
CREATE USER IF NOT EXISTS "aditi.gopalan@sagebase.org";
CREATE USER IF NOT EXISTS "amber.nelson@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.vera@sagebase.org";

// ADTR
CREATE USER IF NOT EXISTS "jessica.malenfant@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.britton@sagebase.org";
CREATE USER IF NOT EXISTS "zoe.leanza@sagebase.org";
CREATE USER IF NOT EXISTS "milan.vu@sagebase.org";
CREATE USER IF NOT EXISTS "william.poehlman@sagebase.org";
CREATE USER IF NOT EXISTS "jo.scanlan@sagebase.org";
CREATE USER IF NOT EXISTS "trisha.zintel@sagebase.org";
CREATE USER IF NOT EXISTS "bishoy.kamel@sagebase.org";
CREATE USER IF NOT EXISTS "jaclyn.beck@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.britton@sagebase.org";
CREATE USER IF NOT EXISTS "karina.leal@sagebase.org";
CREATE USER IF NOT EXISTS "ann.campton@sagebase.org";
CREATE USER IF NOT EXISTS "melissa.klein@sagebase.org";
CREATE USER IF NOT EXISTS "beatriz.saldana@sagebase.org";
CREATE USER IF NOT EXISTS "jordan.driscoll@sagebase.org";
CREATE USER IF NOT EXISTS "laura.heath@sagebase.org";
CREATE USER IF NOT EXISTS "tiara.adams@sagebase.org";
CREATE USER IF NOT EXISTS "emma.costa@sagebase.org";
CREATE USER IF NOT EXISTS "julia.gray@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.lundin@sagebase.org";
CREATE USER IF NOT EXISTS "pranita.atri@sagebase.org";
CREATE USER IF NOT EXISTS "amelia.kallaher@sagebase.org";

// SciData Misc
CREATE USER IF NOT EXISTS "ashley.clayton@sagebase.org";
CREATE USER IF NOT EXISTS "vanessa.barone@sagebase.org";
CREATE USER IF NOT EXISTS "savitha.sangameswaran@sagebase.org";
CREATE USER IF NOT EXISTS "ram.ayyala@sagebase.org";
CREATE USER IF NOT EXISTS "angie.bowen@sagebase.org";
CREATE USER IF NOT EXISTS "tera.derita@sagebase.org";

// NF Rare Disease
CREATE USER IF NOT EXISTS "anh.nguyet.vu@sagebase.org";
CREATE USER IF NOT EXISTS "robert.allaway@sagebase.org";
CREATE USER IF NOT EXISTS "james.moon@sagebase.org";
CREATE USER IF NOT EXISTS "belinda.garana@sagebase.org";

// AdvancedDataAnalytics
CREATE USER IF NOT EXISTS "jineta.banerjee@sagebase.org";
CREATE USER IF NOT EXISTS "orion.banks@sagebase.org";
CREATE USER IF NOT EXISTS "ziwei.pan@sagebase.org";
CREATE USER IF NOT EXISTS "aditya.nath@sagebase.org";

// Digital Health
CREATE USER IF NOT EXISTS "solly.sieberts@sagebase.org";
CREATE USER IF NOT EXISTS "elias.chaibub.neto@sagebase.org";
CREATE USER IF NOT EXISTS "sonia.carlson@sagebase.org";

// Governance
CREATE USER IF NOT EXISTS "kimberly.corrigan@sagebase.org";
CREATE USER IF NOT EXISTS "anthony.pena@sagebase.org";
CREATE USER IF NOT EXISTS "jonathan.liaw-gray@sagebase.org";
CREATE USER IF NOT EXISTS "samuel.cason@sagebase.org";
CREATE USER IF NOT EXISTS "amelia.weixler@sagebase.org";

// CNB
CREATE USER IF NOT EXISTS "verena.chung@sagebase.org";
CREATE USER IF NOT EXISTS "rchai@sagebase.org";
CREATE USER IF NOT EXISTS "gaia.andreoletti@sagebase.org";
// TECH
CREATE USER IF NOT EXISTS "anthony.williams@sagebase.org";
CREATE USER IF NOT EXISTS "milen.nikolov@sagebase.org";
CREATE USER IF NOT EXISTS "amy.heiser@sagebase.org";
CREATE USER IF NOT EXISTS "christina.parry@sagebase.org";
CREATE USER IF NOT EXISTS "ann.novakowski@sagebase.org";
CREATE USER IF NOT EXISTS "samia.ahmed@sagebase.org";
CREATE USER IF NOT EXISTS "shaun.kalweit@sagebase.org";
CREATE USER IF NOT EXISTS "jon.long@sagebase.org";

// DPE
CREATE USER IF NOT EXISTS "bryan.fauble@sagebase.org";
CREATE USER IF NOT EXISTS "rixing.xu@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.yu@sagebase.org";
CREATE USER IF NOT EXISTS "jenny.medina@sagebase.org";
CREATE USER IF NOT EXISTS "phil.snyder@sagebase.org";
CREATE USER IF NOT EXISTS "sophia.jobe@sagebase.org";
CREATE USER IF NOT EXISTS "dan.lu@sagebase.org";
CREATE USER IF NOT EXISTS "lingling.peng@sagebase.org";
CREATE USER IF NOT EXISTS "andrew.lamb@sagebase.org";

// LT
CREATE USER IF NOT EXISTS "luca.foschini@sagebase.org";
CREATE USER IF NOT EXISTS "alberto.pepe@sagebase.org";
CREATE USER IF NOT EXISTS "susheel.varma@sagebase.org";
CREATE USER IF NOT EXISTS "christine.suver@sagebase.org";
CREATE USER IF NOT EXISTS "mackenzie.wildman@sagebase.org";
CREATE USER IF NOT EXISTS "andrea.varsavsky@sagebase.org";
CREATE USER IF NOT EXISTS "dottie.young@sagebase.org";
CREATE USER IF NOT EXISTS "tera.derita@sagebase.org";

// HR
CREATE USER IF NOT EXISTS "dottie.young@sagebase.org";

// FINANCE
CREATE USER IF NOT EXISTS "brandon.morgan@sagebase.org";
CREATE USER IF NOT EXISTS "barry.webb@sagebase.org";
CREATE USER IF NOT EXISTS "sarah.mansfield@sagebase.org";
CREATE USER IF NOT EXISTS "ranell.nystrom@sagebase.org";

// SPONSORED RESEARCH
CREATE USER IF NOT EXISTS "luisa.chekrygin@sagebase.org";
CREATE USER IF NOT EXISTS "laurielle.roberson@sagebase.org";


// SERVICE users
CREATE USER IF NOT EXISTS DPE_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;

CREATE USER IF NOT EXISTS ADMIN_SERVICE
    TYPE = SERVICE; --noqa: LT02, PRS

CREATE USER IF NOT EXISTS DEVELOPER_SERVICE
    TYPE = SERVICE;

CREATE USER IF NOT EXISTS GENIE_SERVICE
TYPE = SERVICE
COMMENT = 'Service user to be used for launching Genie workflows in snowflake';

-- Set DEFAULT_SECONDARY_ROLES based on user type and role access.
-- A user is treated as an analyst if ALL of the following are true:
--   1) user type is not SERVICE
--   2) user name does not contain 'service' (case-insensitive)
--   3) user is not granted any of these roles:
--      DATA_ENGINEER, ACCOUNTADMIN, SYSADMIN, SECURITYADMIN, USERADMIN
-- Analysts get DEFAULT_SECONDARY_ROLES=('ALL').
-- Non-analysts (any user failing one or more checks above) get
-- DEFAULT_SECONDARY_ROLES=().
EXECUTE IMMEDIATE $$
DECLARE
    updated_users ARRAY DEFAULT ARRAY_CONSTRUCT(); -- users we updated
    username STRING; -- a user identifier
    user_type STRING; -- user type from SHOW USERS
    dsr_value STRING; -- default secondary role setting
    normalized_dsr_value STRING; -- normalized default secondary role setting
    role_name STRING; -- role granted to a user
    is_service_user BOOLEAN; -- service users are excluded
    is_excluded_by_role BOOLEAN; -- developers/admins are excluded
    should_enable_all BOOLEAN; -- whether user should receive ['ALL']
    user_cursor CURSOR FOR 
        SELECT "name", "type", "default_secondary_roles" 
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) 
        WHERE "name" <> 'SNOWFLAKE'
            AND LOWER("name") NOT IN (
                'joe.smith@sagebase.org',
                'joni.harker@sagebase.org'
            ); -- Jumpcloud-managed users
    role_cursor CURSOR FOR
        SELECT "name"
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
        WHERE "granted_on" = 'ROLE'; -- A cursor over roles granted to a user
BEGIN
    SHOW USERS;
    OPEN user_cursor;
    LOOP
        -- Iterate through every user returned by SHOW USERS.
        FETCH user_cursor INTO username, user_type, dsr_value;

        -- exit condition
        IF (username IS NULL) THEN
            BREAK;
        END IF;

        LET quoted_username STRING := '"' || :username || '"';
        -- Normalize current value so comparisons work across formatting variants.
        normalized_dsr_value := UPPER(COALESCE(dsr_value, ''));
        -- Service users are excluded by explicit type and by service-like username.
        is_service_user := (UPPER(COALESCE(user_type, '')) = 'SERVICE')
            OR (POSITION('service' IN LOWER(username)) > 0);
        is_excluded_by_role := FALSE;

        IF (NOT is_service_user) THEN
            -- Inspect role grants for this user to detect developer/admin exclusions.
            EXECUTE IMMEDIATE
                'SHOW GRANTS TO USER IDENTIFIER(''' || :quoted_username || ''')';
            -- role_cursor must be opened immediately after each SHOW GRANTS call.
            OPEN role_cursor;
            LOOP
                -- Walk granted roles until we find an excluded role or exhaust results.
                FETCH role_cursor INTO role_name;

                IF (role_name IS NULL) THEN
                    BREAK;
                END IF;

                IF (role_name IN ('DATA_ENGINEER', 'ACCOUNTADMIN', 'SYSADMIN', 'SECURITYADMIN', 'USERADMIN')) THEN
                    -- Any matching role disqualifies the user from analyst treatment.
                    is_excluded_by_role := TRUE;
                    BREAK;
                END IF;
            END LOOP;
            CLOSE role_cursor;
        END IF;

        -- Only non-service users without excluded roles are treated as analysts.
        should_enable_all := (NOT is_service_user) AND (NOT is_excluded_by_role);

        IF (should_enable_all) THEN
            IF (normalized_dsr_value NOT IN ('[''ALL'']', '["ALL"]')) THEN
                -- Enable automatic use of all granted secondary roles for analysts.
                ALTER USER IDENTIFIER(:quoted_username) SET DEFAULT_SECONDARY_ROLES=('ALL');
                updated_users := ARRAY_APPEND(updated_users, username);
            END IF;
        ELSE
            IF (normalized_dsr_value != '[]') THEN
                -- Enforce no default secondary roles for excluded users.
                ALTER USER IDENTIFIER(:quoted_username) SET DEFAULT_SECONDARY_ROLES=();
                updated_users := ARRAY_APPEND(updated_users, username);
            END IF;
        END IF;

    END LOOP;
    CLOSE user_cursor;
    RETURN updated_users;
END;
$$;

-- Disable users only when currently enabled.
EXECUTE IMMEDIATE $$
DECLARE
    updated_users ARRAY DEFAULT ARRAY_CONSTRUCT();
    username STRING;
    disabled_value STRING;
    is_disabled BOOLEAN;
    user_cursor CURSOR FOR
        SELECT "name", "disabled"
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
        WHERE LOWER("name") IN (
            'dbt_service',
            'ad_service',
            'thomasyu888',
            'abby.vanderlinden@sagebase.org',
            'anna.greenwood@sagebase.org',
            'arti.singh@sagebase.org',
            'brad.macdonald@sagebase.org',
            'christina.conrad@sagebase.org',
            'drew.duglan@sagebase.org',
            'hayley.sanchez@sagebase.org',
            'james.eddy@sagebase.org',
            'kim.baggett@sagebase.org',
            'lakaija.johnson@sagebase.org',
            'lisa.pasquale@sagebase.org',
            'natosha.edmonds@sagebase.org',
            'nicholas.lee@sagebase.org',
            'pranav.anbarasu@sagebase.org',
            'richard.yaxley@sagebase.org',
            'sarah.chan@sagebase.org',
            'meghasyam@sagebase.org',
            'thomas.schaffter@sagebase.org',
            'alexander.paynter@sagebase.org',
            'victor.baham@sagebase.org',
            'andree-anne.berthiaume@sagebase.org',
            'maria.diaz@sagebase.org',
            'serghei.mangul@sagebase.org',
            'loren.wolfe@sagebase.org',
            'mieko.hashimoto@sagebase.org',
            'gianna.jordan@sagebase.org'
        );
BEGIN
    SHOW USERS;
    OPEN user_cursor;
    LOOP
        FETCH user_cursor INTO username, disabled_value;

        IF (username IS NULL) THEN
            BREAK;
        END IF;

        is_disabled := UPPER(COALESCE(disabled_value, 'FALSE')) = 'TRUE';

        IF (NOT is_disabled) THEN
            LET quoted_username STRING := '"' || :username || '"';
            ALTER USER IDENTIFIER(:quoted_username) SET DISABLED = TRUE;
            updated_users := ARRAY_APPEND(updated_users, username);
        END IF;
    END LOOP;
    CLOSE user_cursor;
    RETURN updated_users;
END;
$$;

-- This user is owned by the Jumpcloud provisioner integration
-- ALTER USER "JOE.SMITH@SAGEBASE.ORG" SET DISABLED = TRUE;
