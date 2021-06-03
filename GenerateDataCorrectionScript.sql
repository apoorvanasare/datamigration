 
create or replace PROCEDURE PROC_GEN_DATA_CORR_SCRIPT
(exec_type IN VARCHAR2 DEFAULT '%',
pk_column IN CHAR DEFAULT 'N',
ipAzureSchema IN VARCHAR2 DEFAULT '%', 
ipAzureTable IN VARCHAR2 DEFAULT '%',
Final_qry  OUT CLOB) AS
BEGIN
declare

  DB_Linkname VARCHAR2(100) := '@dblink_name'; --- Add DB link name here
  final_qry CLOB;
  upd_qry CLOB;
  ins_qry CLOB;
  azure_schema varchar2(100);
  azure_table	varchar2(100); 
  azure_col    varchar2(100);
  legacy_schema varchar2(100);
  legacy_table varchar2(100);
  legacy_col   varchar2(100); 
  

  
   CURSOR c1 is
	SELECT distinct AZURE_SCHEMA, AZURE_TABLE, AZURE_COLUMN, LEGACY_SCHEMA, 
		   LEGACY_TABLE, LEGACY_COLUMN, PK_VALUE, CURRENT_LEGACY_VALUE, PRE_AZURE_VALUE
	FROM SA_PTM_SUPPORT.VALIDATION_REPORT_COL_WISE_1
	where CURRENT_LEGACY_VALUE <> PRE_AZURE_VALUE 
    --AND UPPER (AZURE_COLUMN) LIKE UPPER (TRIM (ipAzurecolumn)) 
	AND UPPER (Azure_Schema) LIKE UPPER (TRIM (ipAzureSchema)) 
    AND UPPER (azure_table) LIKE  UPPER (TRIM (ipAzureTable)) ;
	
	CURSOR c2 IS
	SELECT distinct Azure_Schema,
					Azure_Table,
					Legacy_Schema,
					Legacy_Table
	FROM  DATA_MAPPING_CONFIG
	where UPPER (Azure_Schema) LIKE UPPER (TRIM (ipAzureSchema)) 
    AND UPPER (Azure_Table) LIKE  UPPER (TRIM (ipAzureTable)) ;
	

BEGIN
  FOR rec IN c1 LOOP
  
	azure_schema    := rec.AZURE_SCHEMA;
	azure_table	  := rec.AZURE_TABLE;
	azure_col    := rec.AZURE_COLUMN;
	legacy_schema    := rec.LEGACY_SCHEMA;
	legacy_table	  := rec.LEGACY_TABLE;
	legacy_col    := rec.LEGACY_COLUMN;
    Final_qry:=null;

	
	IF exec_type = 'UPD' THEN

		IF rec.CURRENT_LEGACY_VALUE <> rec.PRE_AZURE_VALUE THEN

		upd_qry:= 'UPDATE '||azure_schema||'.'|| azure_table||' a
			   SET '||azure_col ||' = (SELECT '||legacy_col ||'
               FROM '||legacy_schema||'.'||legacy_table||DB_Linkname||' B
               WHERE a.'||pk_column ||' = B.'||pk_column||')
               WHERE EXISTS (SELECT 1 FROM '||legacy_schema||'.'||legacy_table||DB_Linkname||' B
             WHERE a.'||pk_column ||' = B.'||pk_column||
                   ' AND A.'||azure_col||' <> B.'||legacy_col ||')';
		
        Final_qry:=	upd_qry;	   
				   
		dbms_output.put_line ( Final_qry ) ;			   
		END IF;
	END IF;
	
	 END LOOP;
	
    FOR rec_ins IN c2 LOOP
	  
	  azure_schema    := rec_ins.AZURE_SCHEMA;
	  azure_table	  := rec_ins.AZURE_TABLE;
	  legacy_schema    := rec_ins.LEGACY_SCHEMA;
	  legacy_table	  := rec_ins.LEGACY_TABLE;
      Final_qry:=null;
	
	IF exec_type = 'INS'  THEN
	
	  --DBMS_OUTPUT.enable(1000000);

		SELECT INS.INSERT_STMT||' '||RECS.SELECT_ROWS || ' FROM '||RECS.OWNER||'.'||RECS.TABLE_NAME||DB_Linkname
		||' WHERE NOT EXISTS ( SELECT 1 FROM '||INS.OWNER||'.'||INS.TABLE_NAME ||
		' WHERE '||INS.OWNER||'.'||pk_column ||' = '||RECS.OWNER||'.'|| pk_column ||' ));' 
		RUN_ME_TO_GET_INSERT_SCRIPT into ins_qry
		FROM
		(
		SELECT ATC.OWNER, ATC.TABLE_NAME, ' ( SELECT '||LISTAGG(
		case when data_type like 'CHAR' then 'TRIM(' || column_name || ')' else column_name end ,
		', ') WITHIN GROUP (ORDER BY ATC.COLUMN_ID) SELECT_ROWS
		FROM ALL_TAB_COLUMNS ATC
		WHERE ATC.TABLE_NAME = azure_table and ATC.OWNER = azure_schema
		GROUP BY ATC.OWNER, ATC.TABLE_NAME
		) RECS,
		(
		SELECT ATC.OWNER, ATC.TABLE_NAME, 'INSERT /* +APPEND */ INTO '||ATC.OWNER||'.'||ATC.TABLE_NAME||' ('||LISTAGG(ATC.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY ATC.COLUMN_ID)||') VALUES ' INSERT_STMT
		FROM ALL_TAB_COLUMNS ATC
		WHERE ATC.TABLE_NAME = ipAzureTable and ATC.OWNER = azure_schema
		GROUP BY ATC.OWNER, ATC.TABLE_NAME
		) INS
		WHERE --RECS.OWNER = INS.OWNER AND
		 RECS.TABLE_NAME = INS.TABLE_NAME;
 
        Final_qry:=	ins_qry;

        dbms_output.put_line (Final_qry);
	
    END IF;
	END LOOP; 
	
END;
END PROC_GEN_DATA_CORR_SCRIPT;
/

