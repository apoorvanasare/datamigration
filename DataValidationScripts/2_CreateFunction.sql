create or replace FUNCTION PREPARE_SELECTOR(scm IN VARCHAR2,tbl IN VARCHAR2,clm IN VARCHAR2,l_clm IN VARCHAR2,prefix IN VARCHAR2)
   RETURN VARCHAR2
   IS colmn VARCHAR2(255);
   BEGIN
      SELECT DECODE(data_type,
                    'NUMBER','TRUNC(',
                    'DATE','TRUNC(',
                    'FLOAT','TRUNC(',
                    'BLOB','dbms_lob.substr(',
                    'CLOB','dbms_lob.substr(',
                    'VARCHAR2','TRIM(',
                    'NVARCHAR2','TRIM(',
                     'TIMESTAMP(6)','TRUNC(',
                    'CHAR','TRIM('
                    ,'NULL') ||prefix||nvl(l_clm,column_name)||DECODE(data_type,
                    'NUMBER',')',
                    'DATE',')',
                    'FLOAT',')',
                    'BLOB',', 3500, 1 )',
                    'CLOB',', 3500, 1 )',
                    'VARCHAR2',')',
                    'NVARCHAR2',')',
                     'TIMESTAMP(6)',')',
                    'CHAR',')',
                    'NULL') as c
      INTO colmn
      FROM dba_tab_columns
     WHERE table_name = tbl
     AND owner=scm
     AND COLUMN_NAME = clm;
     RETURN(colmn);
    END;
 /