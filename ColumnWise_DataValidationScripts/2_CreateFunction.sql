
create or replace FUNCTION get_column_format_post_rpt (ip_column IN VARCHAR2, ip_type IN VARCHAR2, ip_alias IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2 IS
sString VARCHAR2(1000);
scolumn VARCHAR2(50);
BEGIN
  IF (ip_alias IS NULL) THEN
     scolumn := ip_column;
  ELSE
     scolumn := ip_alias||'.'||ip_column;
  END IF;
  IF (ip_type IN ('FLOAT','NUMBER')) THEN
    sString := 'TRUNC(NVL('||scolumn||',0),6)' ;
  ELSIF (ip_type IN ('CHAR', 'VARCHAR2')) THEN
    sString := 'NVL('||scolumn||',''-1'')' ;
  ELSIF (ip_type IN ('DATE','TIMESTAMP(6)')) THEN
    sString := 'TRUNC(NVL('||scolumn||',SYSDATE))' ;
  ELSE
    sString := scolumn;
  END IF;
  RETURN (sString);
END;
/
