-- cumulative data volume for AD Knowledge Portal
-- this is used for consortium reporting and conference materials

create or replace view sage.ad.datatype_cumulative_volume as
with ad_files as (
    select distinct
        id,
        file_handle_id,
        created_on,
        annotations:annotations:dataType:value[0] as datatype,
        annotations:annotations:assay:value[0] as assay
    from synapse_data_warehouse.synapse.node_latest
    where project_id = '2580853' and node_type = 'file' and is_public = 'true'
),

assay_group as (
    select
        id,
        file_handle_id,
        created_on,
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
            else 'other'
        end as simple_assay
    from ad_files
),

file_size_type as (
    select
        assay_group.id,
        assay_group.file_handle_id,
        f.content_size,
        assay_group.simple_assay,
        date_trunc('month', assay_group.created_on) as month_created
    from assay_group
    left join synapse_data_warehouse.synapse.file_latest as f
        on assay_group.file_handle_id = f.id
),

date_range as (
    select
        date_trunc('month', min(created_on)) as start_date,
        date_trunc('month', current_date) as end_date,
        datediff(month, start_date, end_date) as number_months
    from ad_files
),

months as (
    select date_trunc('month', dateadd(month, seq4(), date_range.start_date)) as month_created
    from
        date_range,
        -- need to figure out how to get this rowcount value to be dynamic based on months
        table(generator(rowcount => 1000))
),

assay_types as (
    select distinct simple_assay
    from assay_group
),

all_combinations as (
    select
        m.month_created,
        a.simple_assay
    from
        months as m
    cross join
        assay_types as a
),

monthly_total as (
    select
        ac.simple_assay,
        ac.month_created,
        coalesce(sum(ft.content_size), 0) as monthly_volume
    from all_combinations as ac
    left join file_size_type as ft
        on
            ac.month_created = ft.month_created
            and ac.simple_assay = ft.simple_assay
    where
        ac.month_created < dateadd(month, 1, date_trunc('month', current_date))
    group by ac.month_created, ac.simple_assay
)

select
    month_created,
    simple_assay,
    sum(monthly_volume)
        over (
            partition by simple_assay
            order by
                month_created asc
            rows between unbounded preceding and current row
        )
        as cumulative_volume
from monthly_total
order by month_created desc, simple_assay asc;
