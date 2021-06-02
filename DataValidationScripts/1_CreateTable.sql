  CREATE TABLE DATA_MAPPING_CONFIG
   (
    SERVICE VARCHAR2(255 BYTE), 
	LEGACY_SCHEMA VARCHAR2(20 BYTE), 
	LEGACY_TABLE VARCHAR2(255 BYTE), 
	LEGACY_COLUMN VARCHAR2(255 BYTE), 
	AZURE_SCHEMA VARCHAR2(255 BYTE), 
	AZURE_TABLE VARCHAR2(255 BYTE), 
	AZURE_COLUMN VARCHAR2(255 BYTE), 
	LEGACY_DATA_TYPE VARCHAR2(50 BYTE), 
	LEGACY_DATA_LENGTH NUMBER, 
	LEGACY_DATA_NULLABLE CHAR(1 BYTE), 
	AZURE_DATA_TYPE VARCHAR2(50 BYTE), 
	AZURE_DATA_LENGTH NUMBER, 
	AZURE_NULLABLE CHAR(1 BYTE), 
	LAST_RUN DATE, 
	UPDATED CHAR(1 BYTE) DEFAULT 'Y', 
	LEGACY_COUNT NUMBER, 
	AZURE_COUNT NUMBER, 
	EXECUTIONTIMEINSECS NUMBER, 
	LEGACY_OGG_DIFF NUMBER, 
	AZURE_OGG_DIFF NUMBER, 
	ERR_MSG VARCHAR2(2000 BYTE), 
	COMBINE CHAR(1 BYTE) DEFAULT 'Y', 
	CRITERIA_L VARCHAR2(1000 BYTE), 
	CRITERIA_A VARCHAR2(100 BYTE), 
	MOD_DATE_FLAG VARCHAR2(10 BYTE) DEFAULT 'N', 
	AZURE_QUERY CLOB, 
	LEGACY_QUERY CLOB,
    GROUP_ID NUMBER
   );