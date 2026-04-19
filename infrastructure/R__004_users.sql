USE ROLE USERADMIN;

-- Platform
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

-- Cancer Bio
CREATE USER IF NOT EXISTS "adam.taylor@sagebase.org";
CREATE USER IF NOT EXISTS "chelsea.nayan@sagebase.org";
CREATE USER IF NOT EXISTS "xindi.guo@sagebase.org";
CREATE USER IF NOT EXISTS "alexander.paynter@sagebase.org";
CREATE USER IF NOT EXISTS "aditi.gopalan@sagebase.org";
CREATE USER IF NOT EXISTS "amber.nelson@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.vera@sagebase.org";

-- ADTR
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
CREATE USER IF NOT EXISTS "karina.leal@sagebase.org";
CREATE USER IF NOT EXISTS "ann.campton@sagebase.org";
CREATE USER IF NOT EXISTS "melissa.klein@sagebase.org";
CREATE USER IF NOT EXISTS "beatriz.saldana@sagebase.org";
CREATE USER IF NOT EXISTS "andree-anne.berthiaume@sagebase.org";
CREATE USER IF NOT EXISTS "jordan.driscoll@sagebase.org";
CREATE USER IF NOT EXISTS "laura.heath@sagebase.org";
CREATE USER IF NOT EXISTS "tiara.adams@sagebase.org";
CREATE USER IF NOT EXISTS "emma.costa@sagebase.org";
CREATE USER IF NOT EXISTS "julia.gray@sagebase.org";

-- SciData
CREATE USER IF NOT EXISTS "ashley.clayton@sagebase.org";
CREATE USER IF NOT EXISTS "vanessa.barone@sagebase.org";
CREATE USER IF NOT EXISTS "savitha.sangameswaran@sagebase.org";
CREATE USER IF NOT EXISTS "ram.ayyala@sagebase.org";
CREATE USER IF NOT EXISTS "angie.bowen@sagebase.org";
CREATE USER IF NOT EXISTS "tera.derita@sagebase.org";

-- NF Rare Disease
CREATE USER IF NOT EXISTS "anh.nguyet.vu@sagebase.org";
CREATE USER IF NOT EXISTS "robert.allaway@sagebase.org";
CREATE USER IF NOT EXISTS "james.moon@sagebase.org";
CREATE USER IF NOT EXISTS "belinda.garana@sagebase.org";

-- Advanced Data Analytics
CREATE USER IF NOT EXISTS "jineta.banerjee@sagebase.org";
CREATE USER IF NOT EXISTS "orion.banks@sagebase.org";
CREATE USER IF NOT EXISTS "ziwei.pan@sagebase.org";
CREATE USER IF NOT EXISTS "aditya.nath@sagebase.org";

-- Digital Health
CREATE USER IF NOT EXISTS "solly.sieberts@sagebase.org";
CREATE USER IF NOT EXISTS "elias.chaibub.neto@sagebase.org";
CREATE USER IF NOT EXISTS "sonia.carlson@sagebase.org";

-- Governance
CREATE USER IF NOT EXISTS "kimberly.corrigan@sagebase.org";
CREATE USER IF NOT EXISTS "anthony.pena@sagebase.org";
CREATE USER IF NOT EXISTS "jonathan.liaw-gray@sagebase.org";
CREATE USER IF NOT EXISTS "samuel.cason@sagebase.org";
CREATE USER IF NOT EXISTS "amelia.weixler@sagebase.org";

-- CNB
CREATE USER IF NOT EXISTS "verena.chung@sagebase.org";
CREATE USER IF NOT EXISTS "rchai@sagebase.org";
CREATE USER IF NOT EXISTS "maria.diaz@sagebase.org";
CREATE USER IF NOT EXISTS "gaia.andreoletti@sagebase.org";
CREATE USER IF NOT EXISTS "serghei.mangul@sagebase.org";

-- Tech
CREATE USER IF NOT EXISTS "anthony.williams@sagebase.org";
CREATE USER IF NOT EXISTS "loren.wolfe@sagebase.org";
CREATE USER IF NOT EXISTS "mieko.hashimoto@sagebase.org";
CREATE USER IF NOT EXISTS "milen.nikolov@sagebase.org";
CREATE USER IF NOT EXISTS "amy.heiser@sagebase.org";
CREATE USER IF NOT EXISTS "christina.parry@sagebase.org";
CREATE USER IF NOT EXISTS "ann.novakowski@sagebase.org";
CREATE USER IF NOT EXISTS "samia.ahmed@sagebase.org";
CREATE USER IF NOT EXISTS "shaun.kalweit@sagebase.org";

-- DPE
CREATE USER IF NOT EXISTS "bryan.fauble@sagebase.org";
CREATE USER IF NOT EXISTS "rixing.xu@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.yu@sagebase.org";
CREATE USER IF NOT EXISTS "jenny.medina@sagebase.org";
CREATE USER IF NOT EXISTS "phil.snyder@sagebase.org";
CREATE USER IF NOT EXISTS "sophia.jobe@sagebase.org";
CREATE USER IF NOT EXISTS "dan.lu@sagebase.org";
CREATE USER IF NOT EXISTS "lingling.peng@sagebase.org";
CREATE USER IF NOT EXISTS "gianna.jordan@sagebase.org";
CREATE USER IF NOT EXISTS "andrew.lamb@sagebase.org";

-- LT / Leadership
CREATE USER IF NOT EXISTS "luca.foschini@sagebase.org";
CREATE USER IF NOT EXISTS "alberto.pepe@sagebase.org";
CREATE USER IF NOT EXISTS "susheel.varma@sagebase.org";
CREATE USER IF NOT EXISTS "christine.suver@sagebase.org";
CREATE USER IF NOT EXISTS "mackenzie.wildman@sagebase.org";
CREATE USER IF NOT EXISTS "andrea.varsavsky@sagebase.org";
CREATE USER IF NOT EXISTS "dottie.young@sagebase.org";
CREATE USER IF NOT EXISTS "brandon.morgan@sagebase.org";

-- Finance
CREATE USER IF NOT EXISTS "barry.webb@sagebase.org";
CREATE USER IF NOT EXISTS "sarah.mansfield@sagebase.org";
CREATE USER IF NOT EXISTS "ranell.nystrom@sagebase.org";

-- Sponsored Research
CREATE USER IF NOT EXISTS "luisa.chekrygin@sagebase.org";
CREATE USER IF NOT EXISTS "laurielle.roberson@sagebase.org";

-- Service users
CREATE USER IF NOT EXISTS DPE_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;

CREATE USER IF NOT EXISTS ADMIN_SERVICE
    TYPE = SERVICE;

CREATE USER IF NOT EXISTS DEVELOPER_SERVICE
    TYPE = SERVICE;

CREATE USER IF NOT EXISTS GENIE_SERVICE
    TYPE = SERVICE
    COMMENT = 'Service user to be used for launching Genie workflows in snowflake';

-- Disabled users (departed or deprecated)
ALTER USER IF EXISTS DBT_SERVICE SET DISABLED = TRUE;
ALTER USER IF EXISTS AD_SERVICE SET DISABLED = TRUE;
ALTER USER IF EXISTS THOMASYU888 SET DISABLED = TRUE;
ALTER USER IF EXISTS "abby.vanderlinden@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "anna.greenwood@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "arti.singh@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "brad.macdonald@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "christina.conrad@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "drew.duglan@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "hayley.sanchez@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "james.eddy@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "kim.baggett@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "lakaija.johnson@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "lisa.pasquale@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "natosha.edmonds@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "nicholas.lee@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "pranav.anbarasu@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "richard.yaxley@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "sarah.chan@sagebase.org" SET DISABLED = TRUE;
ALTER USER IF EXISTS "meghasyam@sagebase.org" SET DISABLED = TRUE;
