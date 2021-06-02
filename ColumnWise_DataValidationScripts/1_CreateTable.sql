
/*Input table*/

CREATE TABLE MAPPING_PK_CONFIG
(ID	NUMBER	,
MicroServiceName	VARCHAR2(255 BYTE)	,
Legacy_Schema	VARCHAR2(255 BYTE)	,
Legacy_Table	VARCHAR2(255 BYTE)	,
LegacyColumn	VARCHAR2(255 BYTE)	,
Azure_DB	VARCHAR2(255 BYTE)	,
Azure_Schema	VARCHAR2(255 BYTE)	,
Azure_Table	VARCHAR2(255 BYTE)	,
AzureColumn	VARCHAR2(255 BYTE)	,
Comments	VARCHAR2(255 BYTE)	,
PK_COLUMN	VARCHAR2(1 BYTE)	,
PK_OPERATOR	VARCHAR2(20 BYTE)	,
PK_CRITERIA	VARCHAR2(1000 BYTE)	,
PK_POSITION	NUMBER	,
UPDATED	VARCHAR2(1 BYTE)	,
RECORDS_DIFF	NUMBER	,
LEGACY_DIFF	NUMBER	,
AZURE_DIFF	NUMBER	,
ERROR_CODE	VARCHAR2(4000 BYTE)	,
DATA_TYPE	VARCHAR2(30 BYTE)	,
AZURE_DATA_TYPE	VARCHAR2(30 BYTE)	,
SQL_STMT	VARCHAR2(4000 BYTE)	,
AZURE_SQL_STMT	VARCHAR2(4000 BYTE)	,
LEGACY_SQL_STMT	VARCHAR2(4000 BYTE)	,
LEGACY_PK_CRITERIA	VARCHAR2(4000 BYTE)	,
SCRIPT_REQ	VARCHAR2(1 BYTE)	,
STATUS	VARCHAR2(1 BYTE)	,
UPDATED_LEGACY_DIFF	VARCHAR2(1 BYTE)	,
UPDATED_AZURE_DIFF	VARCHAR2(1 BYTE),
DIFF_REQ VARCHAR2(1 BYTE));

/* Output Tables */

CREATE TABLE VALIDATION_REPORT_COL_WISE_1 
(
  ID VARCHAR2(20 BYTE) 
, MICROSERVICE_NAME VARCHAR2(4000 BYTE) 
, AZURE_SCHEMA VARCHAR2(4000 BYTE) 
, AZURE_TABLE VARCHAR2(4000 BYTE) 
, AZURE_COLUMN VARCHAR2(4000 BYTE) 
, LEGACY_SCHEMA VARCHAR2(4000 BYTE) 
, LEGACY_TABLE VARCHAR2(4000 BYTE) 
, LEGACY_COLUMN VARCHAR2(4000 BYTE) 
, PK_VALUE VARCHAR2(4000 BYTE) 
, CURRENT_LEGACY_VALUE VARCHAR2(4000 BYTE) 
, PRE_AZURE_VALUE VARCHAR2(4000 BYTE) 
, POST_AZURE_VALUE VARCHAR2(4000 BYTE) 
, PRE_DIFFERENCE_COUNT NUMBER 
, POST_DIFFERENCE_COUNT NUMBER 
, ERROR VARCHAR2(4000 BYTE) 
, TARGET_ROWID VARCHAR2(4000 CHAR) 
) ;

CREATE TABLE VALIDATION_REPORT_COL_WISE_2 
(
  ID VARCHAR2(20 BYTE) 
, MICROSERVICE_NAME VARCHAR2(4000 BYTE) 
, AZURE_SCHEMA VARCHAR2(4000 BYTE) 
, AZURE_TABLE VARCHAR2(4000 BYTE) 
, AZURE_COLUMN VARCHAR2(4000 BYTE) 
, LEGACY_SCHEMA VARCHAR2(4000 BYTE) 
, LEGACY_TABLE VARCHAR2(4000 BYTE) 
, LEGACY_COLUMN VARCHAR2(4000 BYTE) 
, PK_VALUE VARCHAR2(4000 BYTE) 
, CURRENT_LEGACY_VALUE VARCHAR2(4000 BYTE) 
, PRE_AZURE_VALUE VARCHAR2(4000 BYTE) 
, POST_AZURE_VALUE VARCHAR2(4000 BYTE) 
, PRE_DIFFERENCE_COUNT NUMBER 
, POST_DIFFERENCE_COUNT NUMBER 
, ERROR VARCHAR2(4000 BYTE) 
, TARGET_ROWID VARCHAR2(4000 CHAR) 
) ;