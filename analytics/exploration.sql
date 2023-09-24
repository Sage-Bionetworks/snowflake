USE ROLE PUBLIC;
USE WAREHOUSE compute_org;
use database synapse_data_warehouse;
use schema synapse_raw;

// Explore certified quiz / certified quiz questions
select *
from certifiedquiz
limit 10;

select sum(num_times_quiz)
from 
    (select user_id, count(*) as num_times_quiz from certifiedquiz group by user_id) s
where num_times_quiz > 1;

select *
from
certifiedquizquestion
limit 10;

select distinct INSTANCE
from certifiedquiz;
select count(*)
from certifiedquiz;

select *
from certifiedquizquestionrecords
limit 10;

select RESPONSE_ID, INSTANCE, count(*)
from certifiedquizquestion
group by RESPONSE_ID, INSTANCE
order by RESPONSE_ID ASC;

select *
from certifiedquizquestion
where RESPONSE_ID = 1
order by QUESTION_INDEX ASC;

with no_dups as (
    select distinct * from certifiedquizquestion
)
select count(*)
from no_dups;

// Look for whether or not certain API calls are still used
select distinct USER_AGENT
from processedaccess
where request_url like '%/table/sql/transform' ;

//110486
select count(*)
from synapse_data_warehouse.synapse.user_certified
where PASSED is null;

select PASSED, count(*)
from synapse_data_warehouse.synapse.user_certified
group by PASSED;

// This doesn't have me...
select *
from synapse_data_warehouse.synapse_raw.certifiedquiz
where USER_ID = 3324230;

SELECT *
FROM TABLE(SHOW TABLES IN SCHEMA sage.portal_raw);

SHOW TABLES IN SCHEMA sage.portal_raw;
select * from table(result_scan(last_query_id()));

SELECT *
FROM sage.information_schema.tables
WHERE TABLE_SCHEMA = 'PORTAL_RAW' AND
TABLE_NAME = 'NF';

MERGE INTO AD target_table USING AD_temp src
            ON target_table.id = src.id
            when matched then
                update set target_table.id = src.id,target_table.name = src.name,target_table.study = src.study,target_table.dataType = src.dataType,target_table.assay = src.assay,target_table.organ = src.organ,target_table.tissue = src.tissue,target_table.species = src.species,target_table.sex = src.sex,target_table.consortium = src.consortium,target_table."grant" = src."grant",target_table.modelSystemName = src.modelSystemName,target_table.treatmentType = src.treatmentType,target_table.specimenID = src.specimenID,target_table.individualID = src.individualID,target_table.individualIdSource = src.individualIdSource,target_table.specimenIdSource = src.specimenIdSource,target_table.resourceType = src.resourceType,target_table.dataSubtype = src.dataSubtype,target_table.metadataType = src.metadataType,target_table.assayTarget = src.assayTarget,target_table.analysisType = src.analysisType,target_table.cellType = src.cellType,target_table.nucleicAcidSource = src.nucleicAcidSource,target_table.fileFormat = src.fileFormat,target_table."group" = src."group",target_table.isModelSystem = src.isModelSystem,target_table.isConsortiumAnalysis = src.isConsortiumAnalysis,target_table.isMultiSpecimen = src.isMultiSpecimen,target_table.createdOn = src.createdOn,target_table.createdBy = src.createdBy,target_table.parentId = src.parentId,target_table.currentVersion = src.currentVersion,target_table.benefactorId = src.benefactorId,target_table.projectId = src.projectId,target_table.modifiedOn = src.modifiedOn,target_table.modifiedBy = src.modifiedBy,target_table.dataFileHandleId = src.dataFileHandleId,target_table.metaboliteType = src.metaboliteType,target_table.chromosome = src.chromosome,target_table.modelSystemType = src.modelSystemType,target_table.libraryPrep = src.libraryPrep,target_table.dataFileSizeBytes = src.dataFileSizeBytes
            when not matched then
            insert
            (id,name,study,dataType,assay,organ,tissue,species,sex,consortium,"grant",modelSystemName,treatmentType,specimenID,individualID,individualIdSource,specimenIdSource,resourceType,dataSubtype,metadataType,assayTarget,analysisType,cellType,nucleicAcidSource,fileFormat,"group",isModelSystem,isConsortiumAnalysis,isMultiSpecimen,createdOn,createdBy,parentId,currentVersion,benefactorId,projectId,modifiedOn,modifiedBy,dataFileHandleId,metaboliteType,chromosome,modelSystemType,libraryPrep,dataFileSizeBytes) values(src.id,src.name,src.study,src.dataType,src.assay,src.organ,src.tissue,src.species,src.sex,src.consortium,src."grant",src.modelSystemName,src.treatmentType,src.specimenID,src.individualID,src.individualIdSource,src.specimenIdSource,src.resourceType,src.dataSubtype,src.metadataType,src.assayTarget,src.analysisType,src.cellType,src.nucleicAcidSource,src.fileFormat,src."group",src.isModelSystem,src.isConsortiumAnalysis,src.isMultiSpecimen,src.createdOn,src.createdBy,src.parentId,src.currentVersion,src.benefactorId,src.projectId,src.modifiedOn,src.modifiedBy,src.dataFileHandleId,src.metaboliteType,src.chromosome,src.modelSystemType,src.libraryPrep,src.dataFileSizeBytes);