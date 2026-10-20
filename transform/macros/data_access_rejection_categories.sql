{% macro data_access_rejection_categories() %}
    [
        {
            'label': 'DUC - Missing document',
            'description': 'The required DUC was not submitted.'
        },
        {
            'label': 'DUC - Incorrect version',
            'description': 'The DUC uses an incorrect or outdated template or version.'
        },
        {
            'label': 'DUC - Incomplete form',
            'description': 'Required DUC information is missing or incomplete, excluding signatures and requester mismatches.'
        },
        {
            'label': 'DUC - Requester mismatch',
            'description': 'Requesters, team members, usernames, or Synapse IDs differ between the DUC and access request.'
        },
        {
            'label': 'DUC - Signature or signing authority issue',
            'description': 'A required PI, requester, or official signature is missing or invalid, or the official lacks signing authority.'
        },
        {
            'label': 'IDU - Incorrect version',
            'description': 'The IDU uses an incorrect or outdated template or version.'
        },
        {
            'label': 'IDU - Insufficient research description',
            'description': 'Research purpose, methods, or intended use is inadequately explained, excluding omissions covered by specific IDU categories.'
        },
        {
            'label': 'IDU - Missing study identification',
            'description': 'The IDU does not adequately identify the requested studies or datasets.'
        },
        {
            'label': 'IDU - Missing AI-use information',
            'description': 'Required information about whether or how artificial intelligence will be used is missing or inadequate.'
        },
        {
            'label': 'IDU - Project lead information issue',
            'description': 'The project lead name or identifying information is missing, incomplete, or incorrect.'
        },
        {
            'label': 'IDU - Institution information issue',
            'description': 'The institution name or identifying information is missing, incomplete, abbreviated, or incorrect.'
        },
        {
            'label': 'Documentation - Ethics approval issue',
            'description': 'Required IRB, IEC, or ERC approval documentation is missing or inadequate.'
        },
        {
            'label': 'Eligibility - Research outside permitted scope',
            'description': 'The proposed research conflicts with the permitted research purpose or data-use restrictions.'
        },
        {
            'label': 'Eligibility - Country restriction',
            'description': 'The rejection explicitly cites a country-based access restriction or country-of-concern policy.'
        },
        {
            'label': 'Submission - Test submission',
            'description': 'The submission is explicitly identified as a test rather than a genuine access request.'
        },
        {
            'label': 'Other - Unmapped or unclear reason',
            'description': 'A stated rejection reason falls outside the defined categories, or the explanation is too vague to classify.'
        }
    ]
{% endmacro %}
