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
CREATE USER IF NOT EXISTS "khai.do@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.schaffter@sagebase.org";
-- This user is managed by Jumpcloud, thus they exist outside
-- the usual user creation process.
-- CREATE USER IF NOT EXISTS "joni.harker@sagebase.org";

// Cancer Bio
CREATE USER IF NOT EXISTS "adam.taylor@sagebase.org";
CREATE USER IF NOT EXISTS "chelsea.nayan@sagebase.org";
CREATE USER IF NOT EXISTS "xindi.guo@sagebase.org";
CREATE USER IF NOT EXISTS "alexander.paynter@sagebase.org";
CREATE USER IF NOT EXISTS "angie.bowen@sagebase.org";
CREATE USER IF NOT EXISTS "ashley.clayton@sagebase.org";
CREATE USER IF NOT EXISTS "amber.nelson@sagebase.org";
CREATE USER IF NOT EXISTS "tiara.adams@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.vera@sagebase.org";
CREATE USER IF NOT EXISTS "aditya.nath@sagebase.org";
CREATE USER IF NOT EXISTS "sonia.carlson@sagebase.org";
CREATE USER IF NOT EXISTS "james.moon@sagebase.org";
CREATE USER IF NOT EXISTS "orion.banks@sagebase.org";

// ADTR
CREATE USER IF NOT EXISTS "victor.baham@sagebase.org";
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

// SciData Misc
CREATE USER IF NOT EXISTS "vanessa.barone@sagebase.org";
CREATE USER IF NOT EXISTS "savitha.sangameswaran@sagebase.org";
CREATE USER IF NOT EXISTS "laura.heath@sagebase.org";
CREATE USER IF NOT EXISTS "andree-anne.berthiaume@sagebase.org";
CREATE USER IF NOT EXISTS "jordan.driscoll@sagebase.org";
CREATE USER IF NOT EXISTS "ram.ayyala@sagebase.org";
CREATE USER IF NOT EXISTS "beatriz.saldana@sagebase.org";

// NF
CREATE USER IF NOT EXISTS "anh.nguyet.vu@sagebase.org";
CREATE USER IF NOT EXISTS "robert.allaway@sagebase.org";
CREATE USER IF NOT EXISTS "christina.parry@sagebase.org";
CREATE USER IF NOT EXISTS "jineta.banerjee@sagebase.org";
CREATE USER IF NOT EXISTS "aditi.gopalan@sagebase.org";
CREATE USER IF NOT EXISTS "ziwei.pan@sagebase.org";

// Digital Health
CREATE USER IF NOT EXISTS "solly.sieberts@sagebase.org";
CREATE USER IF NOT EXISTS "meghasyam@sagebase.org";
CREATE USER IF NOT EXISTS "elias.chaibub.neto@sagebase.org";
CREATE USER IF NOT EXISTS "arti.singh@sagebase.org";
CREATE USER IF NOT EXISTS "sonia.carlson@sagebase.org";

// Governance
CREATE USER IF NOT EXISTS "natosha.edmonds@sagebase.org";
CREATE USER IF NOT EXISTS "ann.novakowski@sagebase.org";
CREATE USER IF NOT EXISTS "kimberly.corrigan@sagebase.org";
CREATE USER IF NOT EXISTS "samia.ahmed@sagebase.org";
CREATE USER IF NOT EXISTS "lisa.pasquale@sagebase.org";
CREATE USER IF NOT EXISTS "anthony.pena@sagebase.org";
CREATE USER IF NOT EXISTS "hayley.sanchez@sagebase.org";
CREATE USER IF NOT EXISTS "jonathan.liaw-gray@sagebase.org";

// CNB
CREATE USER IF NOT EXISTS "verena.chung@sagebase.org";
CREATE USER IF NOT EXISTS "rchai@sagebase.org";
CREATE USER IF NOT EXISTS "maria.diaz@sagebase.org";
CREATE USER IF NOT EXISTS "gaia.andreoletti@sagebase.org";
CREATE USER IF NOT EXISTS "serghei.mangul@sagebase.org";

// TECH
CREATE USER IF NOT EXISTS "anthony.williams@sagebase.org";
CREATE USER IF NOT EXISTS "loren.wolfe@sagebase.org";
CREATE USER IF NOT EXISTS "mieko.hashimoto@sagebase.org";
CREATE USER IF NOT EXISTS "milen.nikolov@sagebase.org";
CREATE USER IF NOT EXISTS "amy.heiser@sagebase.org";

// DPE
CREATE USER IF NOT EXISTS "bryan.fauble@sagebase.org";
CREATE USER IF NOT EXISTS "rixing.xu@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.yu@sagebase.org";
CREATE USER IF NOT EXISTS "brad.macdonald@sagebase.org";
CREATE USER IF NOT EXISTS "jenny.medina@sagebase.org";
CREATE USER IF NOT EXISTS "phil.snyder@sagebase.org";
CREATE USER IF NOT EXISTS "sophia.jobe@sagebase.org";
CREATE USER IF NOT EXISTS "dan.lu@sagebase.org";
CREATE USER IF NOT EXISTS "lingling.peng@sagebase.org";
CREATE USER IF NOT EXISTS "gianna.jordan@sagebase.org";
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

// finance
CREATE USER IF NOT EXISTS "brandon.morgan@sagebase.org";
CREATE USER IF NOT EXISTS "barry.webb@sagebase.org";
CREATE USER IF NOT EXISTS "sarah.mansfield@sagebase.org";
CREATE USER IF NOT EXISTS "ranell.nystrom@sagebase.org";


// SERVICE users
CREATE USER IF NOT EXISTS DBT_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;
CREATE USER IF NOT EXISTS DPE_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;

CREATE USER IF NOT EXISTS AD_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;

DROP USER IF EXISTS RECOVER_SERVICE;

CREATE USER IF NOT EXISTS ADMIN_SERVICE
    TYPE = SERVICE; --noqa: LT02, PRS

CREATE USER IF NOT EXISTS DEVELOPER_SERVICE
    TYPE = SERVICE;

-- Set DEFAULT_SECONDARY_ROLES to [] (do not use secondary roles by default)
-- for all users
EXECUTE IMMEDIATE $$
DECLARE
    updated_users ARRAY DEFAULT ARRAY_CONSTRUCT(); -- users we updated
    username STRING; -- a user identifier
    dsr STRING; -- default secondary role setting
    user_cursor CURSOR FOR 
        SELECT "name", "default_secondary_roles" 
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) 
        WHERE "name" <> 'SNOWFLAKE'; -- A cursor over our users
BEGIN
    SHOW USERS;
    OPEN user_cursor;
    LOOP
        FETCH user_cursor INTO username, dsr;

        -- exit condition
        IF (username IS NULL) THEN
            BREAK;
        END IF;

        -- loop condition
        IF (dsr != '[]') THEN
            LET quoted_username STRING := '"' || :username || '"';
            ALTER USER IDENTIFIER(:quoted_username) SET DEFAULT_SECONDARY_ROLES=();
            updated_users := ARRAY_APPEND(updated_users, username);
        END IF;
    END LOOP;
    CLOSE user_cursor;
    RETURN updated_users;
END;
$$;
