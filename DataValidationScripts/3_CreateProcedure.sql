
create or replace PROCEDURE PROC_DATA_VALIDATION(ipChangesOnly IN CHAR DEFAULT 'Y',ipByFlag IN VARCHAR2 DEFAULT '%', ipAzureTable IN VARCHAR2 DEFAULT '%',ipGrpID IN NUMBER) AS
BEGIN
declare
sSql_a VARCHAR2(32000);
sSql_l VARCHAR2(32000);
sErr VARCHAR2(1) := 'N';
sEMsg VARCHAR2(2000);
sCriteia_L VARCHAR2(2000);
sCriteia_A VARCHAR2(2000);
sSql_aCount VARCHAR2(2000);
sSql_lCount VARCHAR2(2000);
sSqlModify_Column VARCHAR2(100);
sSqlModify_LColumn VARCHAR2(100);
startTime DATE;
DB_Linkname VARCHAR2(100) := '<DB_LINK_NAME>'; --- Add DB link name here
CURSOR c0 IS
	select distinct ogg_map.updated, 
					ogg_map.Azure_Schema,
					ogg_map.Azure_Table,
					ogg_map.Legacy_Schema,
					ogg_map.Legacy_Table,
					ogg_map.last_run,
					EXECUTIONTIMEINSECS,
					group_id
	from DATA_MAPPING_CONFIG ogg_map
	where (group_id  = ipGrpID or Azure_Table LIKE UPPER(TRIM(ipAzureTable)) )
	or ogg_map.updated= ipByFlag
	order by group_id,Azure_Table;

CURSOR c1 (ip_azure_schema IN VARCHAR2, ip_azure_table IN VARCHAR2) IS
    SELECT m.Legacy_Schema, 
	       m.Legacy_Table, 
		   m.Legacy_Column,
           m.Azure_Schema, 
		   m.Azure_Table, 
		   m.Azure_Column,
           m.CRITERIA_L,
		   m.CRITERIA_A,
		   m.last_run
    from DATA_MAPPING_CONFIG m
    WHERE m.combine ='Y' AND m.Azure_Schema = ip_azure_schema
    AND m.Azure_Table = ip_azure_table
    ORDER BY  m.Azure_Table;


nLCnt NUMBER := 0;
nACnt NUMBER := 0;
nLDailyCnt NUMBER := 0;
nADailyCnt NUMBER := 0;
BEGIN
  FOR Rec IN c0 LOOP

    sErr := 'N';
    sEMsg:='';
	nLCnt := 0;
	nACnt := 0;
	sSql_a:='select ';
	sSql_l:='select ';
	sCriteia_L:='';
	sCriteia_A:='';
	sSql_aCount:=null;
    sSql_lCount:=null;
    sSqlModify_Column:='MODIFY_DATE_TIME';
    sSqlModify_LColumn:='MODIFY_DATE_TIME';
    update DATA_MAPPING_CONFIG ogm
         set
			 updated = 'P'
       where ogm.combine ='Y'
         AND ogm.Azure_Schema = Rec.Azure_Schema
         AND ogm.Azure_Table = Rec.Azure_Table;
       commit;
       dbms_output.put_line('Processing : ' || rec.Azure_Schema || '.' || rec.Azure_Table);



       startTime := sysdate;
    FOR recPK IN c1(rec.Azure_Schema, rec.Azure_Table) 
    LOOP


       sSql_aCount:='Select count(*) from  '||rec.Azure_Schema||'.'||rec.Azure_Table;


            sSql_lCount:='Select count(*) from  '||rec.Legacy_Schema||'.'||rec.Legacy_Table||'@'||DB_Linkname;

        IF recPK.CRITERIA_L is not null THEN
         sCriteia_L:=recPK.CRITERIA_L;
        END IF;


        IF recPK.CRITERIA_A is not null THEN
        sCriteia_A:=recPK.CRITERIA_A;

        END IF;

	   IF sSql_a <> 'select ' THEN
		 sSql_a:=sSql_a||', ';
	   END IF;

	   IF sSql_l <> 'select ' THEN
		 sSql_l:=sSql_l||', ';
	   END IF;

       sSql_a:=sSql_a||PREPARE_SELECTOR(recPK.Azure_Schema,recPK.Azure_Table,recPK.Azure_Column,recPK.Azure_Column,'tbl.');

       sSql_l:=sSql_l||PREPARE_SELECTOR(recPK.Azure_Schema,recPK.Azure_Table,recPK.Azure_Column,recPK.Legacy_Column,'tbl.');


		sSql_l:=sSql_l||' as '||recPK.Azure_Column;
        sSql_a:=sSql_a||' as '||recPK.Azure_Column;



   END LOOP;



	sSql_a:=sSql_a||' from '||rec.Azure_Schema||'.'||rec.Azure_Table||' tbl ';
	sSql_l:=sSql_l||' from '||rec.Legacy_Schema||'.'||rec.Legacy_Table||'@'||DB_Linkname||' tbl ';



	IF (ipChangesOnly = 'Y') THEN
		IF sCriteia_A = '' or sCriteia_A is null THEN
			sSql_a:= sSql_a;
		ELSE
			sSql_a:= sSql_a||' '||sCriteia_A;
		END IF;

		IF sCriteia_L = '' or sCriteia_L is null THEN
			sSql_l:= sSql_l;
		ELSE
			sSql_l:= sSql_l||sCriteia_L;
		END IF;
	END IF;



    IF ipChangesOnly <> 'Y' THEN
		sSql_a:= sSql_a||' '||sCriteia_A;
		sSql_l:= sSql_l||sCriteia_L;
    END IF;

    nLDailyCnt := 0;
    nADailyCnt := 0;
    BEGIN
		IF sSql_aCount is not null THEN
         execute immediate sSql_aCount into nADailyCnt;
        END IF;

        IF sSql_lCount is not null  THEN
       execute immediate sSql_lCount into nLDailyCnt;
        END IF;
			commit;
		  EXCEPTION
    	WHEN OTHERS THEN
    	 sEMsg := SQLERRM;
			  sErr := 'Y';
    END;

    IF sErr = 'Y' Then
      DBMS_OUTPUT.PUT_LINE(rec.Azure_Table||' - '||sEMsg);
       END IF;

    BEGIN

		execute immediate 'select count(*) from ('||sSql_a||' minus '||sSql_l||')' into nACnt;
           DBMS_OUTPUT.PUT_LINE('Diff A- '||nACnt);
			commit;
			  EXCEPTION
			WHEN OTHERS THEN
			 sEMsg := SQLERRM;

			  sErr := 'Y';
     END;

	BEGIN
		execute immediate 'select count(*) from ('||sSql_l||' minus '||sSql_a||')' into nLCnt;

			commit;
			EXCEPTION
			WHEN OTHERS THEN
			 sEMsg := SQLERRM;
               DBMS_OUTPUT.PUT_LINE(rec.Azure_Table||' - '||sEMsg);
			  sErr := 'Y';
    END;

	  update DATA_MAPPING_CONFIG ogm
         set ERR_MSG = sEMsg,
			 last_run= SYSDATE ,
             LEGACY_COUNT = nLDailyCnt,
			 AZURE_COUNT = nADailyCnt,
			 LEGACY_OGG_DIFF = nLCnt,
			 AZURE_OGG_DIFF = nACnt,
             ogm.EXECUTIONTIMEINSECS=(SYSDATE-startTime)*24*60*60,
			 AZURE_QUERY = sSql_a,
			 LEGACY_QUERY = sSql_l,
			 updated = decode(sErr,'Y','E','M','M','Y')
       where ogm.combine ='Y'
         AND ogm.Azure_Schema = Rec.Azure_Schema
         AND ogm.Azure_Table = Rec.Azure_Table;
       commit;
  END LOOP; 
END;
END PROC_DATA_VALIDATION;
/
