-- cumulative downloads of AD Portal data files
-- using the same "simple assay" categories as the cumulative upload view
-- not excluding metadata files currently but we could consider that
-- public files only

create or replace view sage.ad.cumulative_downloads_simple_assay as
with ad_files as (
    select distinct
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as datatype,
        annotations:annotations:assay:value[0] as assay
    from synapse_data_warehouse.synapse.node_latest
    where project_id = '2580853' and node_type = 'file' and is_public = 'true'
),

assay_group as (
    select
        id,
        file_handle_id,
        case
            when datatype = 'metabolomics' then 'targeted metabolomics'
            when
                assay in (
                    'LC-MSMS',
                    'label free mass spectrometry',
                    'TMT quantitation',
                    'TMT quantification',
                    'TMTquantitation',
                    'LC-SRM'
                )
                then 'proteomics'
            when assay in ('snrnaSeq', 'CITESeq', 'scrnaSeq') then 'sc/snRNAseq'
            when
                assay in (
                    'rnaSeq', 'RNAseq', 'RNASeq', 'mRNAcounts', 'rnaArray'
                )
                then 'bulk RNAseq'
            when
                assay in ('exomeSeq', 'wholeGenomeSeq', 'scwholeGenomeSeq')
                then 'WGS'
            when assay in ('ATACSeq', 'ATACseq') then 'bulk ATACseq'
            when
                assay in ('snATACSeq', 'snATACseq', 'scATACSeq')
                then 'sc/snATACseq'
            when
                assay in ('10x Multiome', '10x multiome', 'multiome')
                then '10x multiome'
            when datatype = 'behavior process' then 'behavior'
            when datatype = 'image' then 'image'
            when datatype = 'immunoassay' then 'immunoassay'
            when datatype = 'electrophysiology' then 'electrophysiology'
            else assay
        end as simple_assay
    from ad_files
),

file_size_type as (
    select
        assay_group.id,
        assay_group.file_handle_id,
        f.content_size,
        assay_group.simple_assay
    from assay_group
    left join synapse_data_warehouse.synapse.file_latest as f
        on assay_group.file_handle_id = f.id
),

cumulative_downloads as (
    select
        file_handle_id,
        count(distinct user_id, file_handle_id, record_date) as total_downloads,
        count(distinct user_id) as unique_users
    from synapse_data_warehouse.synapse.filedownload
    where project_id = '2580853'
    group by file_handle_id
)

select
    fst.id,
    fst.file_handle_id,
    fst.simple_assay,
    fst.content_size,
    cd.total_downloads,
    cd.unique_users
from file_size_type as fst
left join cumulative_downloads as cd
    on fst.file_handle_id = cd.file_handle_id;
