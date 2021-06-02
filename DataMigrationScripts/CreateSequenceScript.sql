set define off;
set sqlblanklines off;


SET SERVEROUT ON SIZE 1000000;
SET PAGES 55;
DECLARE
    x              VARCHAR2 (1000);
    maxId          NUMBER;
    sql_text       VARCHAR2 (250);
    sql_text_val   VARCHAR2 (250);
    sql_info       VARCHAR2 (4000);
BEGIN
    DBMS_OUTPUT.enable (1000000);
    FOR x IN (SELECT cols.table_name table_name, cols.column_name column_name,cons.constraint_type FROM all_constraints cons, all_cons_columns cols
                WHERE cols.table_name  in 	('<table_name>')
                AND cons.owner='<schema_name>'
                AND cons.constraint_type = 'P'
                AND cons.constraint_name = cols.constraint_name
                AND cons.owner = cols.owner
                AND cols.position = 1
                ORDER BY cols.table_name, cols.position)
    LOOP
    BEGIN
        sql_text := 'select nvl((max('||x.column_name||')+1),1) from '||<schema_name>||.'|| x.table_name;
        EXECUTE IMMEDIATE sql_text INTO maxId;
        EXECUTE IMMEDIATE 'CREATE SEQUENCE '||<schema_name>||'.'||x.table_name||'_SEQ START WITH '||maxId ||
		' MAXVALUE  999999999999999999999999
					MINVALUE 1
					NOCYCLE
					NOCACHE
					NOORDER';
            --DBMS_OUTPUT.put_line ('Sequence '||<schema_name>||'.' ||x.table_name||'_SEQ has been updated');
        EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.put_line('||<schema_name>||'.' ||x.table_name||'_SEQ: ' || SQLERRM);
        End;
    END LOOP;
END;
/