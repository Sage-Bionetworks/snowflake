# SNOW-406 classification findings

Evaluated on October 20, 2026. The 16-category catalog remains useful, including its rare categories. The baseline classifier matched the ten reviewed pilot records, but the larger evaluation found missed categories in long committee letters and incorrect scope labels. These are prototype results, not validated governance reporting.

## Environment and inputs

Draft PR #443 targets `dev`. Its clone workflow deployed the two-column staging view into `SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_406_REJECTION_CLASSIFICATION.RDS_RAW`.

The production `RDS_RAW.DATA_ACCESS_SUBMISSION_STATUS` source is a dynamic table. It was cloned into the analogous feature location and remains suspended. At copying, production and clone had identical aggregate row hashes and 17,816 rows, including 6,328 currently rejected submissions.

The staging view contains all 6,328 rejected submission IDs and decoded reasons. The dbt unique and not-null tests passed, and decoding matched the existing status staging view on every row. The existing pre-2019 safeguard nullifies 113 reasons; 31 additional reasons are blank. The eligible classification pool is therefore 6,184 explanations.

This source is a current-state snapshot. The historical sample spans older and newer submissions that are currently rejected; it is not a history of every rejection transition.

## Runs and distribution

Four tables were created manually through the Snowflake CLI in the clone's `RDS_RAW` schema:

| Table | Records | Selection |
| --- | ---: | --- |
| `DATA_ACCESS_REJECTION_CLASSIFICATION_10` | 10 | Baseline pilot, hash seed 406 |
| `DATA_ACCESS_REJECTION_CLASSIFICATION_1000` | 1,000 | Baseline historical sample, hash seed 406 |
| `DATA_ACCESS_REJECTION_CLASSIFICATION_RECENT_500` | 500 | Baseline, most recently modified rejected submissions |
| `DATA_ACCESS_REJECTION_CLASSIFICATION_EDGE_V2` | 106 | Optional prompt refinement, targeted difficult cases plus the pilot |

The historical sample's status modification dates run from February 26, 2019 through October 16, 2026. The recent sample runs from July 14 through October 17, 2026. They share 84 submission IDs; 83 received identical label sets in both baseline runs.

Every run completed without function errors or labels outside the catalog. Before viewing the AI output, the agent recorded expected labels for the pilot; all ten matched. This small check is not a human-annotated accuracy estimate.

The following counts use the baseline outputs with successful empty arrays routed to `Other`. Percentages use all sampled submissions, and can total more than 100 because the output is multi-label. These are predicted frequencies, not audited counts of actual causes.

| Category | Historical, n = 1,000 | Recent, n = 500 |
| --- | ---: | ---: |
| DUC - Missing document | 23 (2.3%) | 7 (1.4%) |
| DUC - Incorrect version | 117 (11.7%) | 23 (4.6%) |
| DUC - Incomplete form | 83 (8.3%) | 48 (9.6%) |
| DUC - Requester mismatch | 271 (27.1%) | 108 (21.6%) |
| DUC - Signature or signing authority issue | 224 (22.4%) | 96 (19.2%) |
| IDU - Incorrect version | 0 (0.0%) | 1 (0.2%) |
| IDU - Insufficient research description | 320 (32.0%) | 114 (22.8%) |
| IDU - Missing study identification | 135 (13.5%) | 43 (8.6%) |
| IDU - Missing AI-use information | 14 (1.4%) | 23 (4.6%) |
| IDU - Project lead information issue | 72 (7.2%) | 19 (3.8%) |
| IDU - Institution information issue | 89 (8.9%) | 25 (5.0%) |
| Documentation - Ethics approval issue | 23 (2.3%) | 13 (2.6%) |
| Eligibility - Research outside permitted scope | 7 (0.7%) | 2 (0.4%) |
| Eligibility - Country restriction | 79 (7.9%) | 187 (37.4%) |
| Submission - Test submission | 13 (1.3%) | 1 (0.2%) |
| Other - Unmapped or unclear reason | 66 (6.6%) | 35 (7.0%) |

Country restrictions are much more prominent in the recent sample. A single unstratified sample would obscure that difference.

## Rare categories

Retain all 16 categories for the next evaluation. Each appears in at least one sample, and low predicted counts alone do not establish redundancy.

- **IDU version:** The sole recent example explicitly requests the required IDU template headings. The zero historical count does not mean this category is unusable. The additional general research-description label on that record is questionable.
- **Test submission:** Review of all 14 distinct predicted examples found 13 statements identifying testing or demonstration submissions. One merely asks whether the submission is a test, which does not meet the agreed boundary.
- **Research outside permitted scope:** Review of all nine predicted examples found four citing actual research or data-use restrictions, including prohibited redistribution and permitted research aims. Five instead concern routing industry requests, joining a team, unavailable measures, requester age, or institutional qualifications. Under the agreed boundaries, those five should use `Other`.

Scope is useful but currently too broad in the model's predictions. The review also found an explicit prohibited-sharing explanation incorrectly assigned to `Other`, so the scope counts have omissions as well as false positives.

## Other review and prompt refinement

The model directly selected `Other` for nine historical and five recent records. It returned empty arrays for another 57 historical and 30 recent records despite the task instruction. After overlap, the agent reviewed all 96 distinct records routed to `Other`: 12 explicitly assigned and 84 empty-array fallbacks.

Legitimate `Other` cases include unexplained denials, referrals to another email, duplicate or canceled requests, administrative routing, applicant checklists, one-requester-per-submission requirements, and unavailable data. `REJECTED` therefore includes operational closures as well as substantive access denials.

`Other` was not consistently correct. At least two explicit assignments were unnecessary: one explanation was covered by requester mismatch and ethics documentation, and another by prohibited sharing and a missing signature. Several empty-array records clearly contained existing-category problems, including a missing study list, institutional/project-lead information, and ethics or signature issues. Long Bridge2AI committee letters were a recurring source of missed categories. Some cases also expose a boundary question around requester-list corrections that do not explicitly mention both the DUC and electronic request.

The read-only evaluation layer now maps a successful empty array to `Other`, preserves the original output, and exposes `used_other_fallback`. Errors are kept separate. This ensures complete accounting, but it does not correct a missed category or make `Other` accurate.

The optional refinement uses nine illustrative examples, a stronger task description, and ethics exemption wording. On 106 targeted records, it reduced empty arrays from 84 to 50 and preserved all ten pilot matches. It corrected the prohibited-sharing case and some checklist/affiliation cases, but still missed long letters and introduced a scope label for a conditional policy reminder. Its results were mixed, so the baseline remains the default. This targeted sample is not a representative distribution or independent holdout.

## Measured usage and next design step

`SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY` reported:

| Run | AI credits |
| --- | ---: |
| Pilot 10 | 0.015351120 |
| Historical 1,000 | 1.562483520 |
| Recent 500 | 0.820473300 |
| Targeted refinement 106 | 0.234554940 |
| Total | 2.632862880 |

The account uses `CORTEX_ENABLED_CROSS_REGION = ANY_REGION`. At the [listed global price of $2 per AI credit](https://docs.snowflake.com/en/user-guide/snowflake-cortex/pricing), these runs represent approximately $5.27 of AI inference. The baseline averaged about $0.0032 per classification, or roughly $3 per 30-day month at 30 classifications daily with similar text lengths and one inference per reason. This estimate excludes warehouse compute, storage, additional evaluations, and contract-specific discounts. Snowflake bills category descriptions and examples for every record, and [warehouse costs remain additional](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql-cost).

The next useful step is a governance-reviewed evaluation set covering routine templates, long committee letters, conditional reminders, and genuine catalog gaps. Test classifying individual issue paragraphs for long explanations and compare against whole-letter classification before choosing the production approach. Keep the categories fixed during that comparison, preserve raw outputs and fallback flags, and measure precision and omissions per category. Consider new categories only if repeated, meaningful gaps warrant them; this experiment does not automatically add or remove categories.

*This text was generated in whole or part by AI and has been reviewed for correctness by myself.*
