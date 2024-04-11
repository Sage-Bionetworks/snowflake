USE ROLE AD;
USE WAREHOUSE COMPUTE_XSMALL;
USE DATABASE SYNAPSE_DATA_WAREHOUSE;
USE SCHEMA SYNAPSE;

/* Expand annotations column from NODE_LATEST
Columns are based on AD Portal fileview
file entities only */

CREATE VIEW SAGE.AD.FILE_ANNOTATIONS AS
SELECT
    ID,
    NAME,
    -- annotations from the current portal fileview at syn11346063.2
    ANNOTATIONS:annotations:study:value[0] AS STUDY,
    ANNOTATIONS:annotations:dataType:value[0] AS DATATYPE,
    ANNOTATIONS:annotations:assay:value[0] AS ASSAY,
    ANNOTATIONS:annotations:organ:value[0] AS ORGAN,
    ANNOTATIONS:annotations:tissue:value[0] AS TISSUE,
    ANNOTATIONS:annotations:species:value[0] AS SPECIES,
    ANNOTATIONS:annotations:sex:value[0] AS SEX,
    ANNOTATIONS:annotations:consortium:value[0] AS CONSORTIUM,
    ANNOTATIONS:annotations:"grant":value[0] AS "GRANT",
    ANNOTATIONS:annotations:modelSystemName:value[0] AS MODELSYSTEMNAME,
    ANNOTATIONS:annotations:treatmentType:value[0] AS TREATMENTTYPE,
    ANNOTATIONS:annotations:specimenID:value[0] AS SPECIMENID,
    ANNOTATIONS:annotations:individualIdSource:value[0] AS INDIVIDUALIDSOURCE,
    ANNOTATIONS:annotations:specimenIdSource:value[0] AS SPECIMENIDSOURCE,
    ANNOTATIONS:annotations:resourceType:value[0] AS RESOURCETYPE,
    ANNOTATIONS:annotations:dataSubtype:value[0] AS DATASUBTYPE,
    ANNOTATIONS:annotations:metadataType:value[0] AS METADATATYPE,
    ANNOTATIONS:annotations:assayTarget:value[0] AS ASSAYTARGET,
    ANNOTATIONS:annotations:analysisType:value[0] AS ANALYSISTYPE,
    ANNOTATIONS:annotations:cellType:value[0] AS CELLTYPE,
    ANNOTATIONS:annotations:nucleicAcidSource:value[0] AS NUCLEICACIDSOURCE,
    ANNOTATIONS:annotations:fileFormat:value[0] AS FILEFORMAT,
    ANNOTATIONS:annotations:"group":value[0] AS "GROUP",
    ANNOTATIONS:annotations:isModelSystem:value[0] AS ISMODELSYSTEM,
    ANNOTATIONS:annotations:isConsortiumAnalysis:value[0] AS ISCONSORTIUMANALYSIS, -- noqa: LT05
    ANNOTATIONS:annotations:isMultiSpecimen:value[0] AS ISMULTISPECIMEN,
    ANNOTATIONS:annotations:metaboliteType:value[0] AS METABOLITETYPE,
    ANNOTATIONS:annotations:chromosome:value[0] AS CHROMOSOME,
    ANNOTATIONS:annotations:modelSystemType:value[0] AS MODELSYSTEMTYPE,
    ANNOTATIONS:annotations:libraryPrep:value[0] AS LIBRARYPREP,
    -- add some annotations that are not in the current fileview
    ANNOTATIONS:annotations:cohort:value[0] AS COHORT,
    ANNOTATIONS:annotations:dataContributionGroup:value[0] AS DATACONTRIBUTIONGROUP, -- noqa: LT05
    ANNOTATIONS:annotations:dataGenerationSite:value[0] AS DATAGENERATIONSITE,
    ANNOTATIONS:annotations:isSampleExchange:value[0] AS ISSAMPLEEXCHANGE,
    ANNOTATIONS:annotations:batch:value[0] AS BATCH
FROM NODE_LATEST
WHERE PROJECT_ID = '2580853' AND NODE_TYPE = 'file';
