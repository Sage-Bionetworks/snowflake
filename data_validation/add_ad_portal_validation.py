from dotenv import dotenv_values
import great_expectations as gx

context = gx.get_context()
from expectations.expect_column_values_to_have_list_members import (
    ExpectColumnValuesToHaveListMembers,
)

# Define the datasource name
datasource_name = "synapse_data_warehouse"

query = """
SELECT
    ID,
    NAME,
    -- annotations from the current portal fileview at syn11346063.2
    ANNOTATIONS:annotations:study:value AS STUDY,
    ANNOTATIONS:annotations:dataType:value AS DATATYPE,
    ANNOTATIONS:annotations:assay:value AS ASSAY,
    ANNOTATIONS:annotations:organ:value[0] AS ORGAN,
    ANNOTATIONS:annotations:tissue:value AS TISSUE,
    ANNOTATIONS:annotations:species:value AS SPECIES,
    ANNOTATIONS:annotations:sex:value AS SEX,
    ANNOTATIONS:annotations:consortium:value[0] AS CONSORTIUM,
    ANNOTATIONS:annotations:grant:value AS GRANTNUMBER,
    ANNOTATIONS:annotations:modelSystemName:value AS MODELSYSTEMNAME,
    ANNOTATIONS:annotations:treatmentType:value[0] AS TREATMENTTYPE,
    ANNOTATIONS:annotations:specimenID:value[0] AS SPECIMENID,
    ANNOTATIONS:annotations:individualIdSource:value[0] AS INDIVIDUALIDSOURCE,
    ANNOTATIONS:annotations:specimenIdSource:value[0] AS SPECIMENIDSOURCE,
    ANNOTATIONS:annotations:resourceType:value[0] AS RESOURCETYPE,
    ANNOTATIONS:annotations:dataSubtype:value[0] AS DATASUBTYPE,
    ANNOTATIONS:annotations:metadataType:value[0] AS METADATATYPE,
    ANNOTATIONS:annotations:assayTarget:value[0] AS ASSAYTARGET,
    ANNOTATIONS:annotations:analysisType:value[0] AS ANALYSISTYPE,
    ANNOTATIONS:annotations:cellType:value AS CELLTYPE,
    ANNOTATIONS:annotations:nucleicAcidSource:value[0] AS NUCLEICACIDSOURCE,
    ANNOTATIONS:annotations:fileFormat:value[0] AS FILEFORMAT,
    ANNOTATIONS:annotations:group:value AS GROUPS,
    ANNOTATIONS:annotations:isModelSystem:value[0] AS ISMODELSYSTEM,
    ANNOTATIONS:annotations:isConsortiumAnalysis:value[0] AS ISCONSORTIUMANALYSIS, -- noqa: LT05
    ANNOTATIONS:annotations:isMultiSpecimen:value[0] AS ISMULTISPECIMEN,
    ANNOTATIONS:annotations:metaboliteType:value AS METABOLITETYPE,
    ANNOTATIONS:annotations:chromosome:value[0] AS CHROMOSOME,
    ANNOTATIONS:annotations:modelSystemType:value[0] AS MODELSYSTEMTYPE,
    ANNOTATIONS:annotations:libraryPrep:value[0] AS LIBRARYPREP,
    -- add some annotations that are not in the current fileview
    ANNOTATIONS:annotations:cohort:value AS COHORT,
    ANNOTATIONS:annotations:dataContributionGroup:value AS DATACONTRIBUTIONGROUP, -- noqa: LT05
    ANNOTATIONS:annotations:dataGenerationSite:value[0] AS DATAGENERATIONSITE,
    ANNOTATIONS:annotations:isSampleExchange:value[0] AS ISSAMPLEEXCHANGE,
    ANNOTATIONS:annotations:batch:value[0] AS BATCH
FROM SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST
WHERE PROJECT_ID = '2580853' AND NODE_TYPE = 'file';
"""

# Retrieve the existing datasource
try:
    datasource = context.get_datasource(datasource_name)
    print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    print(f"Failed to retrieve datasource '{datasource_name}': {str(e)}")
    config = dotenv_values("../.env")
    user = config["user"]
    password = config["password"]
    snow_account = config["snowflake_account"]
    database = "synapse_data_warehouse"
    my_connection_string = f"snowflake://{user}:{password}@{snow_account}/{database}/synapse?warehouse=compute_xsmall&role=SYSADMIN"

    datasource = context.sources.add_snowflake(
        name=datasource_name,
        connection_string=my_connection_string,  # Or alternatively, individual connection args
    )

asset_name = "ad_portal"
try:
    table_asset = datasource.get_asset(asset_name)
    # datasource = context.get_datasource(datasource_name)
    # print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    table_asset = datasource.add_query_asset(name=asset_name, query=query)

batch_request = table_asset.build_batch_request()
expectation_suite_name = "ad_portal_expectations"

context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)

columns_to_validate = [
    "ID",
    # "NAME",
    # "STUDY",
    # "DATATYPE",
    # "ASSAY",
    # "ORGAN",
    # "TISSUE",
    # "SPECIES",
    # "SEX",
    # "CONSORTIUM",
    # "GRANTNUMBER",
    # "MODELSYSTEMNAME",
    # "TREATMENTTYPE",
    # "SPECIMENID",
    # "INDIVIDUALIDSOURCE",
    # "SPECIMENIDSOURCE",
    # "RESOURCETYPE",
    # "DATASUBTYPE",
    # "METADATATYPE",
    # "ASSAYTARGET",
    # "ANALYSISTYPE",
    # "CELLTYPE",
    # "NUCLEICACIDSOURCE",
    # "FILEFORMAT",
    # "GROUPS",
    # "ISMODELSYSTEM",
    # "ISCONSORTIUMANALYSIS",
    # "ISMULTISPECIMEN",
    # "METABOLITETYPE",
    # "CHROMOSOME",
    # "MODELSYSTEMTYPE",
    # "LIBRARYPREP",
    # "COHORT",
    # "DATACONTRIBUTIONGROUP",
    # "DATAGENERATIONSITE",
    # "ISSAMPLEEXCHANGE",
    # "BATCH"
]

for column in columns_to_validate:
    validator.expect_column_values_to_not_be_null(column)

# validator.expect_column_values_to_be_in_set(
#     column="datatype",
#     value_set=allowed_values,
# # )
validator.expect_column_values_to_have_list_members(
    column="datatype",
    list_members={
        "Pharmacokinetic Study",
        "analysis",
        "behavior process",
        "chromatinActivity",
        "clinical",
        "demographic",
        "electrophysiology",
        "epigenetics",
        "gene expression",
        "geneExpression",
        "genomicVariants",
        "image",
        "immunoassay",
        "mRNA",
        "metabolomics",
        "metagenomics",
        "proteomics",
    },
)

allowed_study_values = [
    "Abeta_microglia",
    "ACOM",
    "ACT",
    "AD-BXD",
    "AD_CrossSpecies",
    "ADMC_ADNI1",
    "ADMC_ADNI1_NightingaleNMR",
    "ADMC_ADNI2-GO",
    "ADMC_ADNI_BakerLipidomics",
    "ADMC_ADNI_NightingaleNMR",
    "ADMC_ADNI_UHawaiiGutMetabolites",
    "ADMC_UPenn",
    "AD_CrossSpecies",
    "AMP-AD_DiverseCohorts",
    "APOEPSC",
    "APOE-TR",
    "Banner",
    "BCM-DMAS",
    "BLSA",
    "BroadAstrom109",
    "BroadMDMi",
    "BroadiPSC",
    "CHDWB",
    "DiCAD",
    "DiseasePseudotime",
    "DroNc-Seq",
    "DukeAD_PTSD",
    "Emory_ADRC",
    "EmoryDrosophilaTau",
    "Emory_Vascular",
    "eQTLmetaAnalysis",
    "FreshMicro",
    "GJA1_deficiency",
    "HBI_scRNAseq",
    "HBTRC",
    "HDAC1-cKOBrain",
    "IL10_APPmouse",
    "IntegratedProteomics",
    "iPSCAstrocytes",
    "iPSCMicroglia",
    "Jax.IU.Pitt.Proteomics_Metabolomics_Pilot",
    "Jax.IU.Pitt_APP.PS1",
    "Jax.IU.Pitt_APOE4.Trem2.R47H",
    "Jax.IU.Pitt_5XFAD",
    "Jax.IU.Pitt_LOAD1.PrimaryScreen",
    "Jax.IU.Pitt_Levetiracetam_5XFAD",
    "Jax.IU.Pitt_MicrobiomePilot",
    "Jax.IU.Pitt_PrimaryScreen",
    "Jax.IU.Pitt_Rat_TgF344-AD",
    "Jax.IU.Pitt_StrainValidation",
    "Jax.IU.Pitt_Verubecestat_5XFAD",
    "Jax.IU.Pitt_hTau_Trem2",
    "LBP",
    "LillyMicroglia",
    "MC-BrAD",
    "MC-CAA",
    "MC_snRNA",
    "MCMPS",
    "MCSA",
    "MCPB",
    "MIT_ROSMAP_Multiomics",
    "MOA-PAD",
    "MSBB",
    "MSBB_ArrayTissuePanel",
    "MSDM",
    "MSMM",
    "MSSMiPSC",
    "MayoPilotRNAseq",
    "MayoHippocampus",
    "MayoLOADGWAS",
    "MayoRNAseq",
    "MayoeGWAS",
    "MindPhenomeKB",
    "MODEL-AD_JAX_GWAS_Gene_Survey",
    "NPS-AD",
    "omicsADDS",
    "Plxnb1_KO",
    "RNAseq_Harmonization",
    "ROSMAP",
    "ROSMAP-IA",
    "ROSMAP-IN",
    "ROSMAP_CellTypeSpecificHA",
    "ROSMAP_CognitiveResilience",
    "ROSMAP_CognitiveReslience",
    "ROSMAP_Lipidomics_Emory",
    "ROSMAP_MammillaryBody",
    "ROSMAP_bsSeq",
    "ROSMAP_nucleus_hashing",
    "RR_APOE4",
    "SEA-AD",
    "SMIB-AD",
    "SV_xQTL",
    "SY5Y_Emory",
    "SY5Y_REST",
    "SUNYStrokeModel",
    "SuperAgerEpiMap",
    "StJude_BannerSun",
    "TAUAPPms",
    "TASTPM",
    "TWAS",
    "TyrobpKO",
    "TyrobpKO_AppPs1",
    "U1-70_PrimaryCellCulture",
    "UCI_3xTg-AD",
    "UCI_5XFAD",
    "UCI_ABCA7",
    "UCI_ABI3",
    "UCI_Bin1K358R",
    "UCI_CollaborativeCrossLines",
    "UCI_PrimaryScreen",
    "UCI_Trem2_Cuprizone",
    "UCI_Trem2-R47H_NSS",
    "UCI_hAbeta_KI",
    "UCSF_MAC",
    "UFL_Cxcl10",
    "UFLOR_ABI3_GNGT2",
    "UPP",
    "UPennPilot",
    "VMC",
    "VirusResilience_LCL",
    "VirusResilience_Mayo.MSBB.ROSMAP",
    "WallOfTargets",
    "WGS_Harmonization",
    "iPSCAstrocytes",
    "iPSCMicroglia",
    "miR155",
    "mtDNA_AD",
    "rnaSeqReprocessing",
    "rnaSeqSampleSwap",
    "scRNAseq_microglia_wild_ADmice",
    "snRNAseqAD_TREM2",
    "snRNAseqPFC_BA10",
]
validator.expect_column_values_to_have_list_members(
    column="study",
    list_members=allowed_study_values
)
# Usage of the custom expectation remains the same as in the initial code

validator.save_expectation_suite(discard_failed_expectations=False)
