-- monthly download volume by simplified assay/datatype category for ADKP
-- used for consortium reporting and conference materials
create or replace view sage.ad.datatype_monthly_download_volume as
with ad_files as (
    select distinct
        id as entity_id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as datatype,
        annotations:annotations:assay:value[0] as assay
    from synapse_data_warehouse.synapse.node_latest
    where project_id = '2580853' and node_type = 'file' and is_public = 'true'
),

assay_group as (
    select
        entity_id,
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

file_size as (
    select
        assay_group.entity_id,
        f.content_size,
        assay_group.simple_assay
    from assay_group
    left join synapse_data_warehouse.synapse.file_latest as f
        on assay_group.file_handle_id = f.id
),

all_time_downloads as (
    select
        atd.entity_id,
        atd.user_id,
        atd.record_date,
        fs.content_size,
        fs.simple_assay,
        date_trunc('month', atd.record_date) as month_downloaded
    from sage.ad.all_time_downloads as atd
    inner join file_size as fs
        on atd.entity_id = fs.entity_id
),

date_range as (
    select
        date_trunc('month', min(record_date)) as start_date,
        date_trunc('month', current_date) as end_date,
        datediff(month, start_date, end_date) as number_months
    from all_time_downloads
),

months as (
    select
        date_trunc('month', dateadd(month, seq4(), date_range.start_date))
            as month_downloaded
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
        m.month_downloaded,
        a.simple_assay
    from
        months as m
    cross join
        assay_types as a
),

monthly_total as (
    select
        ac.simple_assay,
        ac.month_downloaded,
        bytes_to_tb(coalesce(sum(atd.content_size), 0))
            as monthly_download_volume_tb
    from all_combinations as ac
    left join all_time_downloads as atd
        on
            ac.month_downloaded = atd.month_downloaded
            and ac.simple_assay = atd.simple_assay
    where
        ac.month_downloaded
        < dateadd(month, 1, date_trunc('month', current_date))
    group by ac.month_downloaded, ac.simple_assay
)

select *
from monthly_total
where simple_assay is not null;
