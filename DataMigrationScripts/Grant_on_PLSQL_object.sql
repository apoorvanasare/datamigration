create or replace PROCEDURE GRANT_PLSQL_PREV_GENERIC (schemaName VARCHAR2, object_type VARCHAR2)
AS
BEGIN

    FOR R IN (SELECT owner, object_name
                FROM all_objects
               WHERE owner = UPPER (schemaName) and object_type =UPPER(objecttype))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT EXECUTE  ON '
                             || R.owner
                             || '.'
                             || R.object_name
                             || ' to '
                             || R.owner
                             || '_SELECT';

           /* DBMS_OUTPUT.put_line (
                   'GRANT EXECUTE  ON '
                || R.owner
                || '.'
                || R.object_name
                || ' to '
                || R.owner
                || '_SELECT_ALL');*/
        EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.object_name ||' : '|| SQLERRM);
End;
    END LOOP;
dbms_output.put_line('First loop completed!');


    FOR R IN (SELECT owner, object_name
                FROM all_views
               WHERE owner = UPPER (schemaName))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT EXECUTE,DEBUG  ON '
                             || R.owner
                             || '.'
                             || R.object_name
                             || ' to '
                             || R.owner
                             || '_SUPPORT';

          /*  DBMS_OUTPUT.put_line (
                   'GRANT EXECUTE,DEBUG  ON '
                || R.owner
                || '.'
                || R.object_name
                || ' to '
                || R.owner
                || '_SUPPORT_ALL');*/
           EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.object_name ||' : '|| SQLERRM);
End;
    END LOOP;

dbms_output.put_line('Second loop completed!');

    FOR R IN (SELECT owner, object_name
                FROM all_views
               WHERE owner = UPPER (schemaName))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT ALL PRIVILEGES ON '
                             || R.owner
                             || '.'
                             || R.object_name
                             || ' to '
                             || R.owner
                             || '_ADMIN';

            /*DBMS_OUTPUT.put_line (
                   'GRANT ALL PRIVILEGES  ON '
                || R.owner
                || '.'
                || R.object_name
                || ' to '
                || R.owner
                || '_ADMIN_ALL');*/
           EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.object_name ||' : '|| SQLERRM);
End;
    END LOOP;
dbms_output.put_line('Third loop completed!');

EXCEPTION
    WHEN OTHERS
    THEN
        raise_application_error (-20100,
                                 'error#' || SQLCODE || ' desc: ' || SQLERRM);
        RETURN;

END;
/