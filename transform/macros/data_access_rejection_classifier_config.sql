{% macro data_access_rejection_classifier_config() %}
    {% set use_examples = var('rejection_use_examples', false) %}
    {% if use_examples not in [true, false] %}
        {{ exceptions.raise_compiler_error('rejection_use_examples must be a boolean') }}
    {% endif %}
    {
        {% if use_examples %}
        'task_description': 'Classify explicitly stated rejection problems. DUC means Data Use Certification; IDU means Intended Data Use. Select independent, specific categories only. Ignore boilerplate, hypothetical restrictions, and template examples. Use Other for unclear or additional unmapped problems. Always return at least one label.',
        {% else %}
        'task_description': 'Classify explicitly stated rejection reasons. DUC means Data Use Certification; IDU means Intended Data Use. Select all independent problems, using the most specific label per problem. Distinguish inadequate explanations from prohibited research. Exclude boilerplate and hypothetical requirements. Use Other for unmapped or unclear reasons.',
        {% endif %}
        'output_mode': 'multi'
        {% if use_examples %}
        , 'examples': [
            {
                'input': 'Please see the email we sent for the reason your request was denied.',
                'labels': ['Other - Unmapped or unclear reason'],
                'explanation': 'The reason is not stated in this text.'
            },
            {
                'input': 'Please submit a separate access request for each project.',
                'labels': ['Other - Unmapped or unclear reason'],
                'explanation': 'Separating projects into requests is an administrative requirement outside this catalog.'
            },
            {
                'input': 'Please attach the applicant confirmation checklist and written documentation that your project is exempt from ethics review.',
                'labels': ['Documentation - Ethics approval issue', 'Other - Unmapped or unclear reason'],
                'explanation': 'Missing exemption evidence is an ethics documentation issue. The separate checklist requirement is unmapped. No study identification problem is stated.'
            },
            {
                'input': 'Your IDU proposes sharing derived controlled-access data externally, which the DUC prohibits. The DUC also lacks the signing official signature.',
                'labels': ['Eligibility - Research outside permitted scope', 'DUC - Signature or signing authority issue'],
                'explanation': 'The proposed sharing violates a data-use restriction, and the signature is missing. Neither requires Other or an insufficient research description label.'
            },
            {
                'input': 'Your DUC lists a team username differently from the electronic request. Supply the correct ethics approval letter. Note: if research is outside healthy aging, further approval may be needed.',
                'labels': ['DUC - Requester mismatch', 'Documentation - Ethics approval issue'],
                'explanation': 'The mismatch and ethics documentation are actual problems. The conditional healthy-aging reminder does not establish prohibited research or an unmapped problem.'
            },
            {
                'input': 'Your research is adequately described. Reformat the IDU using the required template headings.',
                'labels': ['IDU - Incorrect version'],
                'explanation': 'Only the IDU format is incorrect. Do not infer insufficient research detail from a template correction.'
            },
            {
                'input': 'Please confirm whether third-party personnel act for your institution or a separate employer so we can determine whether they need a separate request.',
                'labels': ['IDU - Institution information issue', 'Other - Unmapped or unclear reason'],
                'explanation': 'Institutional affiliation and agency status need clarification. Separate request ownership is unmapped. No research description problem is stated.'
            },
            {
                'input': 'Your signing official signature is missing. The official must have oversight authority and ensure ethical data use.',
                'labels': ['DUC - Signature or signing authority issue'],
                'explanation': 'Signing-official responsibilities do not establish missing ethics committee documentation.'
            },
            {
                'input': 'Please identify the requested studies and clarify whether AI will be used.',
                'labels': ['IDU - Missing study identification', 'IDU - Missing AI-use information'],
                'explanation': 'Use the two specific omissions without adding the general insufficient research description category.'
            }
        ]
        {% endif %}
    }
{% endmacro %}
