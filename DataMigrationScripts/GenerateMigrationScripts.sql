
CREATE OR REPLACE FUNCTION <SCHEMA>.GET_DDL( i_owner IN VARCHAR2, i_name IN VARCHAR2, i_type IN VARCHAR2)
    RETURN CLOB
IS
BEGIN
   
    BEGIN
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', FALSE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES', FALSE);
		
        IF I_TYPE = 'TABLE' THEN
            DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'REF_CONSTRAINTS', FALSE);
            DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'CONSTRAINTS', FALSE);
        END IF;
    END;

    RETURN DBMS_METADATA.GET_DDL( SCHEMA => i_owner, NAME => i_name, OBJECT_TYPE => i_type);
    
END;
/




set serverout on size 1000000
set pages 55
spool "C:\Users\MicroserviceName\DDL\<Schema>_CreateTable.sql"
DECLARE
 v_ddl clob;
      CURSOR cur_val is select owner, object_name,object_type from ALL_OBJECTS WHERE OWNER in ('<table_name>') 
	  and object_type = 'TABLE' 
	  and object_name not in (select table_name from all_tables where owner='<schema_name>';
BEGIN
      DBMS_OUTPUT.enable(1000000);
      FOR cur_rec in cur_val
      LOOP
            select dbms_metadata.get_ddl(cur_rec.owner, cur_rec.object_name, cur_rec.object_type) into v_ddl from dual;
			dbms_output.put_line (v_ddl || 'TABLESPACE '|| cur_rec.owner ||';');
      END LOOP;
END;
/

spool off;


spool "C:\Users\MicroserviceName\DDL\<Schema>_index.sql"
DECLARE
 v_ddl clob;
      CURSOR cur_val is select owner, object_name,object_type from ALL_OBJECTS WHERE OWNER = '<schema_name>' 
	  and object_type = 'INDEX' and
      object_name in (select index_name from all_indexes where table_owner='<schema_name>' ;
BEGIN
      DBMS_OUTPUT.enable(1000000);
      FOR cur_rec in cur_val
      LOOP
            select BIP.get_ddl(cur_rec.owner, cur_rec.object_name, cur_rec.object_type) into v_ddl from dual;
			dbms_output.put_line (v_ddl || 'TABLESPACE '|| cur_rec.owner ||'_INDX ;');
      END LOOP;
END;
/

spool off;



---DML--------



select 'INSERT /* +APPEND */ INTO '||a.owner ||'.'||a.table_name ||' SELECT '|| (listagg( c.colname,',') within group (order by c.column_id))
|| ' FROM <source_schema_name>.' || a.table_name || ';'
from all_tables a,
	(select table_name,
			column_id , 
			case when data_type like 'CHAR' then 'TRIM(' || column_name || ')' else column_name end colname
	from all_tab_columns 
	where owner='<source_schema_name>' 
	and table_name in ('<table_name>') 
	order by table_name,column_id asc) c
where a.table_name=c.table_name
and a.owner in ('<target_schema_name>')
and a.table_name in ('<table_name>')
 group by a.owner,a.table_name;
 

 
