
/*Sample Insert statement*/
Insert into PROC_DATA_VALIDATION (SERVICE,LEGACY_SCHEMA,LEGACY_TABLE,LEGACY_COLUMN,AZURE_SCHEMA,AZURE_TABLE,AZURE_COLUMN,LEGACY_DATA_TYPE,LEGACY_DATA_LENGTH,AZURE_DATA_TYPE,AZURE_DATA_LENGTH) 
values ('APP_NAME','SOURCE','TABLE_TEST','COLUMN_TEST','TARGET','TABLE_TEST','COLUMN_TEST','NUMBER',22,'NUMBER',22);
COMMIT;