
DECLARE
    CURSOR cur_schema IS
     SELECT  REGEXP_SUBSTR('schema1,schema2', '[^,]+', 1, LEVEL) AS 
	 azure_schema FROM dual
	 CONNECT BY REGEXP_SUBSTR('schema1,schema2', '[^,]+', 1, LEVEL) IS NOT NULL;           
BEGIN
    FOR i IN cur_schema
    LOOP
    BEGIN
		DBMS_OUTPUT.PUT_LINE ('CREATE ROLE ' || i.azure_schema || '_SELECT_ALL  NOT IDENTIFIED;');
        EXECUTE IMMEDIATE 'CREATE ROLE ' || i.azure_schema || '_SELECT_ALL  NOT IDENTIFIED';
    EXCEPTION    
    WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE ('Error for CREATE ROLE ' || i.azure_schema || '_SELECT_ALL  NOT IDENTIFIED;');
    END;
    BEGIN
		DBMS_OUTPUT.PUT_LINE ('CREATE ROLE  ' || i.azure_schema || '_SUPPORT_ALL  NOT IDENTIFIED;');
		EXECUTE IMMEDIATE 'CREATE ROLE ' || i.azure_schema || '_SUPPORT_ALL  NOT IDENTIFIED';
    EXCEPTION    
    WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE ('Error for CREATE ROLE ' || i.azure_schema || '_SUPPORT_ALL  NOT IDENTIFIED;');
    END;
    BEGIN
		DBMS_OUTPUT.PUT_LINE ('CREATE ROLE ' || i.azure_schema || '_ADMIN_ALL  NOT IDENTIFIED;');
		EXECUTE IMMEDIATE 'CREATE ROLE ' || i.azure_schema || '_ADMIN_ALL  NOT IDENTIFIED';
    EXCEPTION    
    WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE ('Error for CREATE ROLE ' || i.azure_schema || '_ADMIN_ALL  NOT IDENTIFIED;');
    END;
   END LOOP;
END;
/



