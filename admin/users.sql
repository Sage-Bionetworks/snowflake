USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS "diep.thach@sagebase.org";
CREATE USER IF NOT EXISTS "anh.nguyet.vu@sagebase.org";
CREATE USER IF NOT EXISTS "xindi.guo@sagebase.org";
CREATE USER IF NOT EXISTS "abby.vanderlinden@sagebase.org";
CREATE USER IF NOT EXISTS "chelsea.nayan@sagebase.org";
CREATE USER IF NOT EXISTS "alexander.paynter@sagebase.org";
CREATE USER IF NOT EXISTS "x.schildwachter@sagebase.org";
CREATE USER IF NOT EXISTS "natosha.edmonds@sagebase.org";
CREATE USER IF NOT EXISTS "kevin.boske@sagebase.org";
CREATE USER IF NOT EXISTS "robert.allaway@sagebase.org";
CREATE USER IF NOT EXISTS "victor.baham@sagebase.org";
CREATE USER IF NOT EXISTS "meghasyam@sagebase.org";
CREATE USER IF NOT EXISTS "pranav.anbarasu@sagebase.org";
CREATE USER IF NOT EXISTS "elias.chaibub.neto@sagebase.org";
CREATE USER IF NOT EXISTS "john.hill@sagebase.org";
CREATE USER IF NOT EXISTS "bruce.hoff@sagebase.org";
CREATE USER IF NOT EXISTS "marco.marasca@sagebase.org";
CREATE USER IF NOT EXISTS "sandhra.sokhal@sagebase.org";
CREATE USER IF NOT EXISTS "adam.hindman@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.malenfant@sagebase.org";
CREATE USER IF NOT EXISTS "ann.novakowski@sagebase.org";
CREATE USER IF NOT EXISTS "adam.taylor@sagebase.org";
CREATE USER IF NOT EXISTS "angie.bowen@sagebase.org";
CREATE USER IF NOT EXISTS "solly.sieberts@sagebase.org";
CREATE USER IF NOT EXISTS "arti.singh@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.britton@sagebase.org";
CREATE USER IF NOT EXISTS "christina.conrad@sagebase.org";
CREATE USER IF NOT EXISTS "drew.duglan@sagebase.org";
CREATE USER IF NOT EXISTS "zoe.leanza@sagebase.org";
CREATE USER IF NOT EXISTS "jay.hodgson@sagebase.org";
CREATE USER IF NOT EXISTS "milan.vu@sagebase.org";
CREATE USER IF NOT EXISTS "richard.yaxley@sagebase.org";
CREATE USER IF NOT EXISTS "ashley.clayton@sagebase.org";
CREATE USER IF NOT EXISTS "jineta.banerjee@sagebase.org";
CREATE USER IF NOT EXISTS "sarah.chan@sagebase.org";
CREATE USER IF NOT EXISTS "nick.grosenbacher@sagebase.org";
CREATE USER IF NOT EXISTS "khai.do@sagebase.org";
CREATE USER IF NOT EXISTS "lakaija.johnson@sagebase.org";
CREATE USER IF NOT EXISTS "sonia.carlson@sagebase.org";
CREATE USER IF NOT EXISTS "amber.nelson@sagebase.org";
CREATE USER IF NOT EXISTS "tiara.adams@sagebase.org";
CREATE USER IF NOT EXISTS "william.poehlman@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.vera@sagebase.org";
CREATE USER IF NOT EXISTS "aditi.gopalan@sagebase.org";
// CNB
CREATE USER IF NOT EXISTS "thomas.schaffter@sagebase.org";
CREATE USER IF NOT EXISTS "jake.albrecht@sagebase.org";
CREATE USER IF NOT EXISTS "verena.chung@sagebase.org";
CREATE USER IF NOT EXISTS "rchai@sagebase.org";
CREATE USER IF NOT EXISTS "maria.diaz@sagebase.org";
CREATE USER IF NOT EXISTS "gaia.andreoletti@sagebase.org";

// FAIR
CREATE USER IF NOT EXISTS "anthony.williams@sagebase.org";
CREATE USER IF NOT EXISTS "loren.wolfe@sagebase.org";
CREATE USER IF NOT EXISTS "lingling.peng@sagebase.org";
CREATE USER IF NOT EXISTS "gianna.jordan@sagebase.org";
CREATE USER IF NOT EXISTS "mieko.hashimoto@sagebase.org";
CREATE USER IF NOT EXISTS "andrew.lamb@sagebase.org";
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
// governance
CREATE USER IF NOT EXISTS "kimberly.corrigan@sagebase.org";
// LT
CREATE USER IF NOT EXISTS "kim.baggett@sagebase.org";
CREATE USER IF NOT EXISTS "luca.foschini@sagebase.org";
CREATE USER IF NOT EXISTS "alberto.pepe@sagebase.org";
CREATE USER IF NOT EXISTS "susheel.varma@sagebase.org";
CREATE USER IF NOT EXISTS "christine.suver@sagebase.org";
CREATE USER IF NOT EXISTS "anna.greenwood@sagebase.org";
CREATE USER IF NOT EXISTS "mackenzie.wildman@sagebase.org";

// finance
CREATE USER IF NOT EXISTS "brandon.morgan@sagebase.org";

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

CREATE USER IF NOT EXISTS RECOVER_SERVICE
    PASSWORD = 'placeholder'
    MUST_CHANGE_PASSWORD = TRUE;
